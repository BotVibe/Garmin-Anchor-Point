import Toybox.Lang;
import Toybox.WatchUi;

//! Advances UI-smoke phases on START/Enter / tap.
//! Phase order: setup → monitor-inside → monitor-outside → alarm → mute → menu → …
class SmokeNavDelegate extends WatchUi.BehaviorDelegate {

    private var _monitor as AnchorMonitor;
    private var _phase as Number = 0;
    private var _onMonitor as Boolean = false;

    public function initialize(monitor as AnchorMonitor) {
        BehaviorDelegate.initialize();
        _monitor = monitor;
    }

    public function onSelect() as Boolean {
        return advance();
    }

    public function onKey(evt as KeyEvent) as Boolean {
        var key = evt.getKey();
        if ((key == WatchUi.KEY_ENTER) || (key == WatchUi.KEY_START)) {
            return advance();
        }
        if (key == WatchUi.KEY_ESC) {
            return false;
        }
        return true;
    }

    public function onTap(evt as ClickEvent) as Boolean {
        return advance();
    }

    private function advance() as Boolean {
        _phase = (_phase + 1) % 6;
        applyPhase();
        return true;
    }

    private function showMonitor(forceFull as Boolean) as Void {
        _monitor.smokeArmDisplay(forceFull);
        if (_onMonitor) {
            // Already on MonitorView — reseeding + requestUpdate refreshes the same view.
            WatchUi.requestUpdate();
        } else {
            WatchUi.switchToView(new $.MonitorView(_monitor), self, WatchUi.SLIDE_IMMEDIATE);
            _onMonitor = true;
        }
    }

    public function applyPhase() as Void {
        _monitor.smokePrepare();
        if (_phase == 0) {
            _onMonitor = false;
            _monitor.smokeSession().seedSetupGoodGps();
            WatchUi.switchToView(new $.SetupView(_monitor), self, WatchUi.SLIDE_IMMEDIATE);
        } else if (_phase == 1) {
            _monitor.smokeSession().seedMonitoringInside();
            showMonitor(false);
        } else if (_phase == 2) {
            _monitor.smokeSession().seedMonitoringOutside();
            showMonitor(true);
        } else if (_phase == 3) {
            _onMonitor = false;
            _monitor.smokeSession().seedAlarmOutside();
            _monitor.smokeMarkAlarmPushed();
            WatchUi.switchToView(new $.AlarmView(_monitor), self, WatchUi.SLIDE_IMMEDIATE);
        } else if (_phase == 4) {
            // Seed mute before leaving AlarmView so onHide → rearmIfStillOutside stays quiet.
            _monitor.smokeSession().seedMutedOutside();
            showMonitor(true);
        } else {
            _monitor.smokeSession().seedMonitoringInside();
            showMonitor(false);
            _monitor.openStopMenu();
        }
    }

    public function getPhase() as Number {
        return _phase;
    }
}
