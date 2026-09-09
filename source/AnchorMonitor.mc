import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.Application;
import Toybox.Attention;
import Toybox.Lang;
import Toybox.Position;
import Toybox.Time;
import Toybox.Timer;
import Toybox.WatchUi;

//! Central state for the anchor-alarm session.
class AnchorMonitor {

    enum MonitorState {
        STATE_SETUP,
        STATE_MONITORING,
        STATE_ALARM
    }

    private const ALARM_INTERVAL_MS = 2000;

    private var _state as MonitorState = STATE_SETUP;
    private var _radiusMeters as Number = 50;
    private var _radiusIndex as Number = 2;
    private var _anchor as Location?;
    private var _current as Location?;
    private var _accuracy as Quality = Position.QUALITY_NOT_AVAILABLE;
    private var _distanceMeters as Float = 0.0;
    private var _outside as Boolean = false;
    private var _appActive as Boolean = true;
    private var _session as ActivityRecording.Session?;
    private var _sessionStartedAt as Number = 0;
    private var _alarmTimer as Timer.Timer?;
    private var _alarmVisible as Boolean = false;
    private var _alarmViewPushed as Boolean = false;

    //! Constructor — loads default radius from properties.
    public function initialize() as Void {
        var stored = Application.Properties.getValue("DefaultRadiusMeters");
        if (stored != null) {
            setRadiusMeters(stored as Number);
        } else {
            setRadiusMeters(50);
        }
    }

    public function getState() as MonitorState {
        return _state;
    }

    public function isSetup() as Boolean {
        return _state == STATE_SETUP;
    }

    public function isMonitoring() as Boolean {
        return _state == STATE_MONITORING;
    }

    public function isAlarming() as Boolean {
        return _state == STATE_ALARM;
    }

    public function getRadiusMeters() as Number {
        return _radiusMeters;
    }

    public function getDistanceMeters() as Float {
        return _distanceMeters;
    }

    public function getAccuracy() as Quality {
        return _accuracy;
    }

    public function getCurrentLocation() as Location? {
        return _current;
    }

    public function getAnchorLocation() as Location? {
        return _anchor;
    }

    public function isOutside() as Boolean {
        return _outside;
    }

    public function isAppActive() as Boolean {
        return _appActive;
    }

    public function isSessionRecording() as Boolean {
        return (_session != null) && _session.isRecording();
    }

    //! Elapsed monitoring seconds, or 0 if not started.
    public function getElapsedSeconds() as Number {
        if (_sessionStartedAt <= 0) {
            return 0;
        }
        return Time.now().value() - _sessionStartedAt;
    }

    //! Cycle radius through predefined options.
    //! @param delta +1 / -1
    public function nudgeRadius(delta as Number) as Void {
        var options = getRadiusOptions();
        var size = options.size();
        _radiusIndex = (_radiusIndex + delta + size) % size;
        _radiusMeters = options[_radiusIndex];
        Application.Properties.setValue("DefaultRadiusMeters", _radiusMeters);
        recalculate();
        WatchUi.requestUpdate();
    }

    //! Set absolute radius in meters (snaps to nearest option).
    //! @param meters Desired radius
    public function setRadiusMeters(meters as Number) as Void {
        var options = getRadiusOptions();
        var bestIndex = 0;
        var bestDiff = 100000;
        for (var i = 0; i < options.size(); i++) {
            var diff = meters - options[i];
            if (diff < 0) {
                diff = -diff;
            }
            if (diff < bestDiff) {
                bestDiff = diff;
                bestIndex = i;
            }
        }
        _radiusIndex = bestIndex;
        _radiusMeters = options[_radiusIndex];
    }

    //! @return Supported radius presets in meters
    private function getRadiusOptions() as Array<Number> {
        return [15, 25, 50, 75, 100] as Array<Number>;
    }

    //! Update GPS information from Position callback.
    //! @param info Latest Position.Info
    public function onPosition(info as Info) as Void {
        _accuracy = info.accuracy;
        if (info.position != null) {
            _current = info.position;
        }
        if (_state == STATE_MONITORING || _state == STATE_ALARM) {
            recalculate();
            if (_outside && (_state == STATE_MONITORING)) {
                enterAlarm();
            } else if (!_outside && (_state == STATE_ALARM)) {
                // Stay in alarm UI until user acknowledges; keep vibrating while outside.
            }
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
        if (_current == null || !Geo.isFixUsable(_accuracy)) {
            return false;
        }

        _anchor = _current;
        _outside = false;
        _distanceMeters = 0.0;
        _sessionStartedAt = Time.now().value();

        if (Toybox has :ActivityRecording) {
            if (_session != null) {
                if (_session.isRecording()) {
                    _session.stop();
                }
                _session = null;
            }
            _session = ActivityRecording.createSession({
                :name => "Ankeralarm",
                :sport => Activity.SPORT_BOATING,
                :subSport => Activity.SUB_SPORT_GENERIC
            });
            _session.start();
        }

        _state = STATE_MONITORING;
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

        if ((Toybox has :ActivityRecording) && (_session != null)) {
            if (_session.isRecording()) {
                _session.stop();
            }
            if (save) {
                _session.save();
            } else {
                _session.discard();
            }
            _session = null;
        }

        _anchor = null;
        _outside = false;
        _distanceMeters = 0.0;
        _sessionStartedAt = 0;
        _state = STATE_SETUP;
        WatchUi.requestUpdate();
    }

    //! Acknowledge alarm and return to monitoring (re-arm after view closes if still outside).
    public function acknowledgeAlarm() as Void {
        stopAlarmEffects();
        _alarmVisible = false;
        if (_state == STATE_ALARM) {
            _state = STATE_MONITORING;
        }
        WatchUi.requestUpdate();
    }

    //! Called when AlarmView is popped/hidden.
    public function onAlarmViewClosed() as Void {
        _alarmViewPushed = false;
        _alarmVisible = false;
        if (_state == STATE_MONITORING) {
            recalculate();
            if (_outside) {
                enterAlarm();
            }
        }
    }

    public function isAlarmVisible() as Boolean {
        return _alarmVisible;
    }

    private function recalculate() as Void {
        if ((_anchor == null) || (_current == null)) {
            _distanceMeters = 0.0;
            _outside = false;
            return;
        }
        _distanceMeters = Geo.distanceMeters(_anchor, _current);
        _outside = _distanceMeters > _radiusMeters.toFloat();
    }

    private function enterAlarm() as Void {
        _state = STATE_ALARM;
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
        if (_state != STATE_ALARM) {
            stopAlarmEffects();
            return;
        }
        if (_outside) {
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
