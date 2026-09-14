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
    private const BACKLIGHT_REFRESH_SECONDS = 45;
    private const TICK_MS = 1000;

    private var _state as Number = DISPLAY_FULL;
    private var _idleSeconds as Number = 0;
    private var _backlightOnSeconds as Number = 0;
    private var _running as Boolean = false;
    private var _timer as Timer.Timer?;
    private var _forceFull as Boolean = false;

    public function getState() as Number {
        return _state;
    }

    public function isOff() as Boolean {
        return _state == DISPLAY_OFF;
    }

    public function isDim() as Boolean {
        return _state == DISPLAY_DIM;
    }

    //! Start the 1 Hz idle timer (monitoring session).
    public function start() as Void {
        _running = true;
        reset();
        ensureTimer();
        _timer.stop();
        _timer.start(method(:onTick), TICK_MS, true);
    }

    //! Stop idle tracking (setup / app end).
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

    //! User interaction or session start — back to full brightness.
    public function reset() as Void {
        _idleSeconds = 0;
        _forceFull = false;
        applyState(DISPLAY_FULL);
        setBacklight(true);
        _backlightOnSeconds = 0;
        WatchUi.requestUpdate();
    }

    //! While muted or alarming, keep full and do not advance idle.
    //! @param forceFull true to pin display at full
    public function setForceFull(forceFull as Boolean) as Void {
        _forceFull = forceFull;
        if (forceFull) {
            _idleSeconds = 0;
            applyState(DISPLAY_FULL);
            setBacklight(true);
            _backlightOnSeconds = 0;
        }
    }

    //! 1 Hz callback.
    public function onTick() as Void {
        if (!_running) {
            return;
        }

        if (_forceFull) {
            _idleSeconds = 0;
            applyState(DISPLAY_FULL);
            _backlightOnSeconds += 1;
            if (_backlightOnSeconds >= BACKLIGHT_REFRESH_SECONDS) {
                setBacklight(true);
                _backlightOnSeconds = 0;
            }
            WatchUi.requestUpdate();
            return;
        }

        _idleSeconds += 1;
        if (_idleSeconds >= IDLE_OFF_SECONDS) {
            applyState(DISPLAY_OFF);
            setBacklight(false);
            _backlightOnSeconds = 0;
        } else if (_idleSeconds >= IDLE_DIM_SECONDS) {
            applyState(DISPLAY_DIM);
            setBacklight(true);
            _backlightOnSeconds += 1;
            if (_backlightOnSeconds >= BACKLIGHT_REFRESH_SECONDS) {
                setBacklight(true);
                _backlightOnSeconds = 0;
            }
        } else {
            applyState(DISPLAY_FULL);
            _backlightOnSeconds += 1;
            if (_backlightOnSeconds >= BACKLIGHT_REFRESH_SECONDS) {
                setBacklight(true);
                _backlightOnSeconds = 0;
            }
        }
        WatchUi.requestUpdate();
    }

    private function ensureTimer() as Void {
        if (_timer == null) {
            _timer = new Timer.Timer();
        }
    }

    private function applyState(state as Number) as Void {
        _state = state;
    }

    private function setBacklight(on as Boolean) as Void {
        if (Attention has :backlight) {
            Attention.backlight(on);
        }
    }
}
