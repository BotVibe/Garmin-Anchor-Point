import Toybox.Application;
import Toybox.Attention;
import Toybox.Lang;
import Toybox.Position;
import Toybox.Timer;
import Toybox.WatchUi;

//! UI / attention wrapper around AnchorSession.
class AnchorMonitor {

    private const ALARM_INTERVAL_MS = 2000;
    private const ALARM_MODE_BOTH = 0;
    private const ALARM_MODE_TONE = 1;
    private const ALARM_MODE_VIBRATE = 2;

    private var _session as AnchorSession;
    private var _displayIdle as DisplayIdleController;
    private var _alarmTimer as Timer.Timer?;
    private var _snoozeTimer as Timer.Timer?;
    private var _alarmViewPushed as Boolean = false;

    public function initialize() {
        _session = new $.AnchorSession();
        _displayIdle = new $.DisplayIdleController();
        var stored = Application.Properties.getValue("DefaultRadiusMeters");
        if (stored != null) {
            _session.setRadiusMeters(stored as Number);
        }
    }

    public function isSetup() as Boolean {
        return _session.isSetup();
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

    public function isOutside() as Boolean {
        return _session.isOutside();
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
        return _session.getAlarmMuteTotalSeconds();
    }

    public function isDisplayOff() as Boolean {
        return _displayIdle.isOff();
    }

    public function isDisplayDim() as Boolean {
        return _displayIdle.isDim();
    }

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

    public function stopMonitoring() as Void {
        stopAlarmPulse();
        cancelSnoozeTimer();
        _displayIdle.stop();
        _alarmViewPushed = false;
        _session.stopMonitoring();
        WatchUi.requestUpdate();
    }

    public function acknowledgeAlarm() as Void {
        stopAlarmPulse();
        _session.acknowledgeAlarm();
        syncForceFull();
        WatchUi.requestUpdate();
    }

    public function onAlarmViewClosed() as Void {
        _alarmViewPushed = false;
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

    public function onSnoozeExpired() as Void {
        if (_session.rearmIfStillOutside()) {
            enterAlarm();
        } else {
            syncForceFull();
            _displayIdle.reset();
        }
        WatchUi.requestUpdate();
    }

    public function isAlarmViewPushed() as Boolean {
        return _alarmViewPushed;
    }

    private function enterAlarm() as Void {
        cancelSnoozeTimer();
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

        // Tone before vibrate: on many devices vibrate preempts a simultaneous playTone.
        // TONE_LOUD_BEEP is the documented alert tone and is audible on beeper and speaker watches;
        // TONE_ALARM is often gated/silent for Connect IQ apps.
        if (useTone && (Attention has :playTone)) {
            Attention.playTone(Attention.TONE_LOUD_BEEP);
        }
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
    }

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

    private function stopAlarmPulse() as Void {
        if (_alarmTimer != null) {
            _alarmTimer.stop();
        }
    }

    public function openStopMenu() as Void {
        var menu = new WatchUi.Menu2({:title => WatchUi.loadResource(Rez.Strings.MenuStopTitle) as String});
        menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.MenuEnd) as String, null, :end, null));
        menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.MenuCancel) as String, null, :cancel, null));
        WatchUi.pushView(menu, new $.StopMenuDelegate(self), WatchUi.SLIDE_UP);
    }

    private function syncForceFull() as Void {
        _displayIdle.setForceFull(_session.isAlarmMuted() || _session.isAlarming());
    }
}
