import Toybox.Lang;
import Toybox.WatchUi;

class MonitorDelegate extends WatchUi.BehaviorDelegate {

    private var _monitor as AnchorMonitor;

    public function initialize(monitor as AnchorMonitor) {
        BehaviorDelegate.initialize();
        _monitor = monitor;
    }

    public function onMenu() as Boolean {
        if (wakeIfDisplayOff()) {
            return true;
        }
        _monitor.resetDisplayIdle();
        _monitor.openStopMenu();
        return true;
    }

    public function onKey(evt as KeyEvent) as Boolean {
        if (wakeIfDisplayOff()) {
            return true;
        }
        var key = evt.getKey();
        if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
            _monitor.resetDisplayIdle();
            _monitor.openStopMenu();
            return true;
        } else if (key == WatchUi.KEY_UP) {
            _monitor.nudgeRadius(1);
            return true;
        } else if (key == WatchUi.KEY_DOWN) {
            _monitor.nudgeRadius(-1);
            return true;
        } else if (key == WatchUi.KEY_ESC) {
            _monitor.resetDisplayIdle();
            _monitor.openStopMenu();
            return true;
        }
        _monitor.resetDisplayIdle();
        return false;
    }

    public function onBack() as Boolean {
        if (wakeIfDisplayOff()) {
            return true;
        }
        _monitor.resetDisplayIdle();
        _monitor.openStopMenu();
        return true;
    }

    public function onPreviousPage() as Boolean {
        if (wakeIfDisplayOff()) {
            return true;
        }
        _monitor.nudgeRadius(1);
        return true;
    }

    public function onNextPage() as Boolean {
        if (wakeIfDisplayOff()) {
            return true;
        }
        _monitor.nudgeRadius(-1);
        return true;
    }

    public function onTap(evt as ClickEvent) as Boolean {
        if (wakeIfDisplayOff()) {
            return true;
        }
        _monitor.resetDisplayIdle();
        return true;
    }

    private function wakeIfDisplayOff() as Boolean {
        if (_monitor.isDisplayOff()) {
            _monitor.resetDisplayIdle();
            return true;
        }
        return false;
    }

}
