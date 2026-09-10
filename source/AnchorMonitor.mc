import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.Application;
import Toybox.Attention;
import Toybox.Lang;
import Toybox.Position;
import Toybox.Timer;
import Toybox.WatchUi;

//! UI / FIT / attention wrapper around AnchorSession.
class AnchorMonitor {

    private const ALARM_INTERVAL_MS = 2000;

    private var _session as AnchorSession;
    private var _appActive as Boolean = true;
    private var _fitSession as ActivityRecording.Session?;
    private var _alarmTimer as Timer.Timer?;
    private var _alarmVisible as Boolean = false;
    private var _alarmViewPushed as Boolean = false;

    //! Constructor — loads default radius from properties.
    public function initialize() {
        _session = new $.AnchorSession();
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

    public function isSessionRecording() as Boolean {
        return (_fitSession != null) && _fitSession.isRecording();
    }

    public function getElapsedSeconds() as Number {
        return _session.getElapsedSeconds();
    }

    public function nudgeRadius(delta as Number) as Void {
        _session.nudgeRadius(delta);
        Application.Properties.setValue("DefaultRadiusMeters", _session.getRadiusMeters());
        WatchUi.requestUpdate();
    }

    public function setRadiusMeters(meters as Number) as Void {
        _session.setRadiusMeters(meters);
    }

    //! Update GPS information from Position callback.
    //! @param info Latest Position.Info
    public function onPosition(info as Position.Info) as Void {
        var enteredAlarm = _session.updateLocation(info.position, info.accuracy);
        if (enteredAlarm) {
            enterAlarm();
        }
        WatchUi.requestUpdate();
    }

    public function setAppActive(active as Boolean) as Void {
        _appActive = active;
        WatchUi.requestUpdate();
    }

    //! Set anchor at current fix and start monitoring + FIT session.
    //! @return true on success
    public function startMonitoring() as Boolean {
        if (!_session.startMonitoring()) {
            return false;
        }

        if (Toybox has :ActivityRecording) {
            if (_fitSession != null) {
                if (_fitSession.isRecording()) {
                    _fitSession.stop();
                }
                _fitSession = null;
            }
            _fitSession = ActivityRecording.createSession({
                :name => "Anchor Point",
                :sport => Activity.SPORT_BOATING,
                :subSport => Activity.SUB_SPORT_GENERIC
            });
            _fitSession.start();
        }

        stopAlarmEffects();
        WatchUi.requestUpdate();
        return true;
    }

    //! Stop monitoring and optionally save the FIT session.
    //! @param save true to save, false to discard
    public function stopMonitoring(save as Boolean) as Void {
        stopAlarmEffects();
        _alarmVisible = false;
        _alarmViewPushed = false;

        if ((Toybox has :ActivityRecording) && (_fitSession != null)) {
            if (_fitSession.isRecording()) {
                _fitSession.stop();
            }
            if (save) {
                _fitSession.save();
            } else {
                _fitSession.discard();
            }
            _fitSession = null;
        }

        _session.stopMonitoring();
        WatchUi.requestUpdate();
    }

    //! Acknowledge alarm and return to monitoring (re-arm after view closes if still outside).
    public function acknowledgeAlarm() as Void {
        stopAlarmEffects();
        _alarmVisible = false;
        _session.acknowledgeAlarm();
        WatchUi.requestUpdate();
    }

    //! Called when AlarmView is popped/hidden.
    public function onAlarmViewClosed() as Void {
        _alarmViewPushed = false;
        _alarmVisible = false;
        if (_session.rearmIfStillOutside()) {
            enterAlarm();
        }
    }

    public function isAlarmVisible() as Boolean {
        return _alarmVisible;
    }

    private function enterAlarm() as Void {
        _alarmVisible = true;
        pulseAlarm();
        startAlarmTimer();
        if (!_alarmViewPushed) {
            _alarmViewPushed = true;
            WatchUi.pushView(new $.AlarmView(self), new $.AlarmDelegate(self), WatchUi.SLIDE_IMMEDIATE);
        }
        WatchUi.requestUpdate();
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
            stopAlarmEffects();
            return;
        }
        if (_session.isOutside()) {
            pulseAlarm();
        }
        WatchUi.requestUpdate();
    }

    private function pulseAlarm() as Void {
        if (Attention has :vibrate) {
            var vibe = [
                new Attention.VibeProfile(100, 200),
                new Attention.VibeProfile(0, 100),
                new Attention.VibeProfile(100, 200),
                new Attention.VibeProfile(0, 100),
                new Attention.VibeProfile(100, 400)
            ];
            Attention.vibrate(vibe);
        }
        if (Attention has :playTone) {
            Attention.playTone(Attention.TONE_ALARM);
        }
        if (Attention has :backlight) {
            Attention.backlight(true);
        }
    }

    private function stopAlarmEffects() as Void {
        if (_alarmTimer != null) {
            _alarmTimer.stop();
        }
        if (Attention has :backlight) {
            Attention.backlight(false);
        }
    }
}
