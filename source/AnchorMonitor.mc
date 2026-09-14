import Toybox.Application;
import Toybox.Attention;
import Toybox.Lang;
import Toybox.Position;
import Toybox.Timer;
import Toybox.WatchUi;

//! UI / attention wrapper around AnchorSession.
class AnchorMonitor {

    private const ALARM_INTERVAL_MS = 2000;
    //! AlarmMode property: tone + vibrate
    private const ALARM_MODE_BOTH = 0;
    //! AlarmMode property: tone only
    private const ALARM_MODE_TONE = 1;
    //! AlarmMode property: vibrate only
    private const ALARM_MODE_VIBRATE = 2;

    private var _session as AnchorSession;
    private var _displayIdle as DisplayIdleController;
    private var _appActive as Boolean = true;
    private var _alarmTimer as Timer.Timer?;
    private var _snoozeTimer as Timer.Timer?;
    private var _alarmVisible as Boolean = false;
    private var _alarmViewPushed as Boolean = false;

    //! Constructor — loads default radius from properties.
    public function initialize() {
        _session = new $.AnchorSession();
        _displayIdle = new $.DisplayIdleController();
        var stored = Application.Properties.getValue("DefaultRadiusMeters");
        if (stored != null) {
            _session.setRadiusMeters(stored as Number);
        }
    }

    public function getSession() as AnchorSession {
        return _session;
    }

    public function isSetup() as Boolean {
        return _session.isSetup();
    }

    public function isMonitoring() as Boolean {
        return _session.isMonitoring();
    }

    public function isAlarming() as Boolean {
        return _session.isAlarming();
    }

    public function getRadiusMeters() as Number {
        return _session.getRadiusMeters();
    }

    public function getDistanceMeters() as Float {
        return _session.getDistanceMeters();
    }

    public function getAccuracy() as Quality {
        return _session.getAccuracy();
    }

    public function getCurrentLocation() as Location? {
        return _session.getCurrentLocation();
    }

    public function getAnchorLocation() as Location? {
        return _session.getAnchorLocation();
    }

    public function isOutside() as Boolean {
        return _session.isOutside();
    }

    public function isAppActive() as Boolean {
        return _appActive;
    }

    public function getElapsedSeconds() as Number {
        return _session.getElapsedSeconds();
    }

    public function isAlarmMuted() as Boolean {
        return _session.isAlarmMuted();
    }

    public function getAlarmMuteRemainingSeconds() as Number {
        return _session.getAlarmMuteRemainingSeconds();
    }

    public function getAlarmMuteTotalSeconds() as Number {
        return 60;
    }

    //! Display power state: DisplayIdleController.DISPLAY_* 
    public function getDisplayPowerState() as Number {
        return _displayIdle.getState();
    }

    public function isDisplayOff() as Boolean {
        return _displayIdle.isOff();
    }

    public function isDisplayDim() as Boolean {
        return _displayIdle.isDim();
    }

    //! Wake / reset idle timeout (user action or session start).
    public function resetDisplayIdle() as Void {
        syncForceFull();
        if (!_session.isAlarmMuted() && !_session.isAlarming()) {
            _displayIdle.reset();
        } else {
            _displayIdle.setForceFull(true);
            WatchUi.requestUpdate();
        }
    }

    public function nudgeRadius(delta as Number) as Void {
        resetDisplayIdle();
        _session.nudgeRadius(delta);
        Application.Properties.setValue("DefaultRadiusMeters", _session.getRadiusMeters());
        WatchUi.requestUpdate();
        dismissAlarmViewIfCleared();
    }

    public function setRadiusMeters(meters as Number) as Void {
        resetDisplayIdle();
        _session.setRadiusMeters(meters);
        dismissAlarmViewIfCleared();
    }

    //! Update GPS information from Position callback.
    //! @param info Latest Position.Info
    public function onPosition(info as Position.Info) as Void {
        var enteredAlarm = _session.updateLocation(info.position, info.accuracy);
        if (enteredAlarm) {
            enterAlarm();
        } else {
            dismissAlarmViewIfCleared();
        }
        syncForceFull();
        WatchUi.requestUpdate();
    }

    public function setAppActive(active as Boolean) as Void {
        _appActive = active;
        WatchUi.requestUpdate();
    }

    //! Set anchor at current fix and start monitoring.
    //! @return true on success
    public function startMonitoring() as Boolean {
        if (!_session.startMonitoring()) {
            return false;
        }

        stopAlarmPulse();
        cancelSnoozeTimer();
        _displayIdle.start();
        resetDisplayIdle();
        WatchUi.requestUpdate();
        return true;
    }

    //! Stop monitoring and return to setup state.
    public function stopMonitoring() as Void {
        stopAlarmPulse();
        cancelSnoozeTimer();
        _displayIdle.stop();
        _alarmVisible = false;
        _alarmViewPushed = false;
        _session.stopMonitoring();
        WatchUi.requestUpdate();
    }

    //! Acknowledge alarm: silence + snooze; keep display full with mute UI.
    public function acknowledgeAlarm() as Void {
        stopAlarmPulse();
        _alarmVisible = false;
        _session.acknowledgeAlarm();
        syncForceFull();
        _displayIdle.setForceFull(true);
        if (Attention has :backlight) {
            Attention.backlight(true);
        }
        WatchUi.requestUpdate();
    }

    //! Called when AlarmView is popped/hidden.
    public function onAlarmViewClosed() as Void {
        _alarmViewPushed = false;
        _alarmVisible = false;
        if (_session.rearmIfStillOutside()) {
            enterAlarm();
        } else {
            scheduleSnoozeCheck();
            syncForceFull();
            if (!_session.isAlarmMuted()) {
                _displayIdle.reset();
            }
        }
    }

    //! Timer callback after acknowledge snooze ends.
    public function onSnoozeExpired() as Void {
        if (_session.rearmIfStillOutside()) {
            enterAlarm();
        } else {
            syncForceFull();
            _displayIdle.reset();
        }
        WatchUi.requestUpdate();
    }

    public function isAlarmVisible() as Boolean {
        return _alarmVisible;
    }

    //! True while the alarm view is on the WatchUi stack.
    public function isAlarmViewPushed() as Boolean {
        return _alarmViewPushed;
    }

    private function enterAlarm() as Void {
        cancelSnoozeTimer();
        _alarmVisible = true;
        syncForceFull();
        pulseAlarm();
        startAlarmTimer();
        if (!_alarmViewPushed) {
            _alarmViewPushed = true;
            WatchUi.pushView(new $.AlarmView(self), new $.AlarmDelegate(self), WatchUi.SLIDE_IMMEDIATE);
        }
        WatchUi.requestUpdate();
    }

    private function dismissAlarmViewIfCleared() as Void {
        if (_alarmViewPushed && !_session.isAlarming()) {
            stopAlarmPulse();
            _alarmVisible = false;
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        }
    }

    private function scheduleSnoozeCheck() as Void {
        var remaining = _session.getAlarmMuteRemainingSeconds();
        if (remaining <= 0) {
            return;
        }
        if (_snoozeTimer == null) {
            _snoozeTimer = new Timer.Timer();
        }
        _snoozeTimer.stop();
        _snoozeTimer.start(method(:onSnoozeExpired), remaining * 1000, false);
    }

    private function cancelSnoozeTimer() as Void {
        if (_snoozeTimer != null) {
            _snoozeTimer.stop();
        }
    }

    private function startAlarmTimer() as Void {
        if (_alarmTimer == null) {
            _alarmTimer = new Timer.Timer();
        }
        _alarmTimer.stop();
        _alarmTimer.start(method(:onAlarmTick), ALARM_INTERVAL_MS, true);
    }

    //! Timer callback — repeat vibe/tone while alarming and outside.
    public function onAlarmTick() as Void {
        if (!_session.isAlarming()) {
            stopAlarmPulse();
            return;
        }
        if (_session.isOutside()) {
            pulseAlarm();
        }
        WatchUi.requestUpdate();
    }

    private function pulseAlarm() as Void {
        var mode = getAlarmMode();
        var useVibrate = (mode == ALARM_MODE_BOTH) || (mode == ALARM_MODE_VIBRATE);
        var useTone = (mode == ALARM_MODE_BOTH) || (mode == ALARM_MODE_TONE);

        if (useVibrate && (Attention has :vibrate)) {
            var vibe = [
                new Attention.VibeProfile(100, 200),
                new Attention.VibeProfile(0, 100),
                new Attention.VibeProfile(100, 200),
                new Attention.VibeProfile(0, 100),
                new Attention.VibeProfile(100, 400)
            ];
            Attention.vibrate(vibe);
        }
        if (useTone && (Attention has :playTone)) {
            Attention.playTone(Attention.TONE_ALARM);
        }
        if (Attention has :backlight) {
            Attention.backlight(true);
        }
    }

    //! Read AlarmMode from app settings (0 both, 1 tone, 2 vibrate).
    //! @return Normalized alarm mode constant
    private function getAlarmMode() as Number {
        var stored = Application.Properties.getValue("AlarmMode");
        if (stored == null) {
            return ALARM_MODE_BOTH;
        }
        var mode = stored as Number;
        if ((mode == ALARM_MODE_TONE) || (mode == ALARM_MODE_VIBRATE)) {
            return mode;
        }
        return ALARM_MODE_BOTH;
    }

    //! Stop vibe/tone timer without forcing backlight off (idle owns backlight).
    private function stopAlarmPulse() as Void {
        if (_alarmTimer != null) {
            _alarmTimer.stop();
        }
    }

    private function syncForceFull() as Void {
        var force = _session.isAlarmMuted() || _session.isAlarming();
        _displayIdle.setForceFull(force);
    }
}
