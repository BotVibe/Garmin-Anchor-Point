import Toybox.Lang;
import Toybox.Position;
import Toybox.Time;

//! Pure monitoring state (no UI, timers, or FIT recording).
//! Used by AnchorMonitor and covered by Run No Evil unit tests.
class AnchorSession {

    enum SessionState {
        STATE_SETUP,
        STATE_MONITORING,
        STATE_ALARM
    }

    private var _state as SessionState = STATE_SETUP;
    private var _radiusMeters as Number = 50;
    private var _radiusIndex as Number = 2;
    private var _anchor as Location?;
    private var _current as Location?;
    private var _accuracy as Quality = Position.QUALITY_NOT_AVAILABLE;
    private var _distanceMeters as Float = 0.0;
    private var _outside as Boolean = false;
    private var _sessionStartedAt as Number = 0;

    public function initialize() as Void {
        setRadiusMeters(50);
    }

    public function getState() as SessionState {
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

    public function getRadiusIndex() as Number {
        return _radiusIndex;
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

    //! Elapsed monitoring seconds, or 0 if not started.
    public function getElapsedSeconds() as Number {
        if (_sessionStartedAt <= 0) {
            return 0;
        }
        return Time.now().value() - _sessionStartedAt;
    }

    //! Cycle radius through presets.
    //! @param delta +1 / -1
    public function nudgeRadius(delta as Number) as Void {
        _radiusIndex = RadiusPresets.nudgeIndex(_radiusIndex, delta);
        _radiusMeters = RadiusPresets.valueAt(_radiusIndex);
        recalculate();
    }

    //! Snap radius to nearest preset.
    //! @param meters Desired radius
    public function setRadiusMeters(meters as Number) as Void {
        _radiusIndex = RadiusPresets.indexOfNearest(meters);
        _radiusMeters = RadiusPresets.valueAt(_radiusIndex);
        recalculate();
    }

    //! Apply a GPS update.
    //! @param location Latest location (may be null to keep previous)
    //! @param accuracy Position.QUALITY_* value
    //! @return true if this update caused a transition into ALARM
    public function updateLocation(location as Location?, accuracy as Quality) as Boolean {
        _accuracy = accuracy;
        if (location != null) {
            _current = location;
        }

        var enteredAlarm = false;
        if (_state == STATE_MONITORING || _state == STATE_ALARM) {
            recalculate();
            if (_outside && (_state == STATE_MONITORING)) {
                _state = STATE_ALARM;
                enteredAlarm = true;
            }
        }
        return enteredAlarm;
    }

    //! Arm monitoring using the current usable fix as the anchor.
    //! @return true on success
    public function startMonitoring() as Boolean {
        if (_current == null || !Geo.isFixUsable(_accuracy)) {
            return false;
        }

        _anchor = _current;
        _outside = false;
        _distanceMeters = 0.0;
        _sessionStartedAt = Time.now().value();
        _state = STATE_MONITORING;
        return true;
    }

    //! Stop monitoring and clear anchor state.
    public function stopMonitoring() as Void {
        _anchor = null;
        _outside = false;
        _distanceMeters = 0.0;
        _sessionStartedAt = 0;
        _state = STATE_SETUP;
    }

    //! Leave ALARM and return to MONITORING (caller may re-check breach).
    public function acknowledgeAlarm() as Void {
        if (_state == STATE_ALARM) {
            _state = STATE_MONITORING;
        }
    }

    //! After alarm UI closes: re-enter alarm if still outside.
    //! @return true if alarm should be shown again
    public function rearmIfStillOutside() as Boolean {
        if (_state != STATE_MONITORING) {
            return false;
        }
        recalculate();
        if (_outside) {
            _state = STATE_ALARM;
            return true;
        }
        return false;
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
