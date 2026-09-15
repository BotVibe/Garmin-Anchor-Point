import Toybox.Lang;
import Toybox.Position;
import Toybox.Time;

//! Pure monitoring state (no UI, timers, or activity recording).
class AnchorSession {

    enum SessionState {
        STATE_SETUP,
        STATE_MONITORING,
        STATE_ALARM
    }

    //! After acknowledge, suppress re-alarm this long so radius/end stay usable.
    const ALARM_SNOOZE_SECONDS = 60;

    private var _state as SessionState = STATE_SETUP;
    private var _radiusMeters as Number = 50;
    private var _radiusIndex as Number = 2;
    private var _anchor as Location?;
    private var _current as Location?;
    private var _accuracy as Quality = Position.QUALITY_NOT_AVAILABLE;
    private var _distanceMeters as Float = 0.0;
    private var _outside as Boolean = false;
    private var _sessionStartedAt as Number = 0;
    private var _alarmMutedUntil as Number = 0;

    public function initialize() {
        setRadiusMeters(50);
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

    public function getAnchorLocation() as Location? {
        return _anchor;
    }

    public function isOutside() as Boolean {
        return _outside;
    }

    public function getElapsedSeconds() as Number {
        if (_sessionStartedAt <= 0) {
            return 0;
        }
        return Time.now().value() - _sessionStartedAt;
    }

    public function isAlarmMuted() as Boolean {
        return getAlarmMuteRemainingSeconds() > 0;
    }

    public function getAlarmMuteRemainingSeconds() as Number {
        if (_alarmMutedUntil <= 0) {
            return 0;
        }
        var remaining = _alarmMutedUntil - Time.now().value();
        if (remaining <= 0) {
            _alarmMutedUntil = 0;
            return 0;
        }
        return remaining;
    }

    public function muteAlarmFor(seconds as Number) as Void {
        if (seconds <= 0) {
            _alarmMutedUntil = 0;
        } else {
            _alarmMutedUntil = Time.now().value() + seconds;
        }
    }

    public function nudgeRadius(delta as Number) as Void {
        _radiusIndex = RadiusPresets.nudgeIndex(_radiusIndex, delta);
        _radiusMeters = RadiusPresets.valueAt(_radiusIndex);
        recalculate();
        clearAlarmIfInside();
    }

    public function setRadiusMeters(meters as Number) as Void {
        _radiusIndex = RadiusPresets.indexOfNearest(meters);
        _radiusMeters = RadiusPresets.valueAt(_radiusIndex);
        recalculate();
        clearAlarmIfInside();
    }

    public function updateLocation(location as Location?, accuracy as Quality) as Boolean {
        _accuracy = accuracy;
        if (location != null) {
            _current = location;
        }

        var enteredAlarm = false;
        if (_state == STATE_MONITORING || _state == STATE_ALARM) {
            recalculate();
            if (!_outside) {
                _alarmMutedUntil = 0;
            }
            if (_state == STATE_ALARM) {
                clearAlarmIfInside();
            } else if (_outside && !isAlarmMuted()) {
                _state = STATE_ALARM;
                enteredAlarm = true;
            }
        }
        return enteredAlarm;
    }

    public function startMonitoring() as Boolean {
        if (_current == null || !Geo.isFixGood(_accuracy)) {
            return false;
        }

        _anchor = _current;
        _outside = false;
        _distanceMeters = 0.0;
        _sessionStartedAt = Time.now().value();
        _alarmMutedUntil = 0;
        _state = STATE_MONITORING;
        return true;
    }

    public function stopMonitoring() as Void {
        _anchor = null;
        _outside = false;
        _distanceMeters = 0.0;
        _sessionStartedAt = 0;
        _alarmMutedUntil = 0;
        _state = STATE_SETUP;
    }

    public function acknowledgeAlarm() as Void {
        if (_state == STATE_ALARM) {
            _state = STATE_MONITORING;
            muteAlarmFor(ALARM_SNOOZE_SECONDS);
        }
    }

    public function rearmIfStillOutside() as Boolean {
        if (_state != STATE_MONITORING) {
            return false;
        }
        recalculate();
        if (!_outside) {
            _alarmMutedUntil = 0;
            return false;
        }
        if (isAlarmMuted()) {
            return false;
        }
        _state = STATE_ALARM;
        return true;
    }

    private function clearAlarmIfInside() as Void {
        if ((_state == STATE_ALARM) && !_outside) {
            _state = STATE_MONITORING;
            _alarmMutedUntil = 0;
        }
    }

    private function recalculate() as Void {
        if ((_anchor == null) || (_current == null)) {
            _distanceMeters = 0.0;
            _outside = false;
            return;
        }
        _distanceMeters = Geo.distanceMeters(_anchor, _current);
        _outside = Geo.isOutsideRadius(_distanceMeters, _radiusMeters);
    }
}
