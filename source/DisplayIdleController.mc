import Toybox.Attention;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

//! Idle display power: full → dim @30s → off @40s; mute/alarm stay full.
class DisplayIdleController {

    const DISPLAY_FULL = 0;
    const DISPLAY_DIM = 1;
    const DISPLAY_OFF = 2;

    private const IDLE_DIM_SECONDS = 30;
    private const IDLE_OFF_SECONDS = 40;
    private const TICK_MS = 1000;

    private var _state as Number = DISPLAY_FULL;
    private var _idleSeconds as Number = 0;
    private var _running as Boolean = false;
    private var _timer as Timer.Timer?;
    private var _forceFull as Boolean = false;
    private var _backlightOn as Boolean = false;

    public function isOff() as Boolean {
        return _state == DISPLAY_OFF;
    }

    public function isDim() as Boolean {
        return _state == DISPLAY_DIM;
    }

    public function start() as Void {
        _running = true;
        reset();
        ensureTimer();
        _timer.stop();
        _timer.start(method(:onTick), TICK_MS, true);
    }

    public function stop() as Void {
        _running = false;
        if (_timer != null) {
            _timer.stop();
        }
        _idleSeconds = 0;
        _state = DISPLAY_FULL;
        _forceFull = false;
        setBacklight(false);
    }

    public function reset() as Void {
        _idleSeconds = 0;
        _forceFull = false;
        _state = DISPLAY_FULL;
        setBacklight(true);
        WatchUi.requestUpdate();
    }

    public function setForceFull(forceFull as Boolean) as Void {
        if (_forceFull == forceFull) {
            if (forceFull) {
                _idleSeconds = 0;
                _state = DISPLAY_FULL;
            }
            return;
        }
        _forceFull = forceFull;
        if (forceFull) {
            _idleSeconds = 0;
            _state = DISPLAY_FULL;
            setBacklight(true);
        }
    }

    public function onTick() as Void {
        if (!_running) {
            return;
        }

        if (_forceFull) {
            _idleSeconds = 0;
            _state = DISPLAY_FULL;
            WatchUi.requestUpdate();
            return;
        }

        _idleSeconds += 1;
        if (_idleSeconds >= IDLE_OFF_SECONDS) {
            _state = DISPLAY_OFF;
            setBacklight(false);
        } else if (_idleSeconds >= IDLE_DIM_SECONDS) {
            _state = DISPLAY_DIM;
        } else {
            _state = DISPLAY_FULL;
        }
        WatchUi.requestUpdate();
    }

    private function ensureTimer() as Void {
        if (_timer == null) {
            _timer = new Timer.Timer();
        }
    }

    //! Only call Attention.backlight on actual on/off transitions.
    private function setBacklight(on as Boolean) as Void {
        if (on == _backlightOn) {
            return;
        }
        _backlightOn = on;
        if (Attention has :backlight) {
            Attention.backlight(on);
        }
    }
}
