import Toybox.Lang;
import Toybox.WatchUi;

class AlarmDelegate extends WatchUi.BehaviorDelegate {

    private var _monitor as AnchorMonitor;

    public function initialize(monitor as AnchorMonitor) {
        BehaviorDelegate.initialize();
        _monitor = monitor;
    }

    public function onSelect() as Boolean {
        return acknowledge();
    }

    public function onBack() as Boolean {
        return acknowledge();
    }

    public function onMenu() as Boolean {
        _monitor.resetDisplayIdle();
        _monitor.openStopMenu();
        return true;
    }

    public function onPreviousPage() as Boolean {
        return nudgeRadius(1);
    }

    public function onNextPage() as Boolean {
        return nudgeRadius(-1);
    }

    public function onKey(evt as KeyEvent) as Boolean {
        var key = evt.getKey();
        if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START || key == WatchUi.KEY_ESC) {
            return acknowledge();
        } else if (key == WatchUi.KEY_UP) {
            return nudgeRadius(1);
        } else if (key == WatchUi.KEY_DOWN) {
            return nudgeRadius(-1);
        } else if (key == WatchUi.KEY_MENU) {
            _monitor.resetDisplayIdle();
            _monitor.openStopMenu();
            return true;
        }
        return true;
    }

    public function onTap(evt as ClickEvent) as Boolean {
        return acknowledge();
    }

    private function acknowledge() as Boolean {
        _monitor.acknowledgeAlarm();
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }

    private function nudgeRadius(delta as Number) as Boolean {
        _monitor.nudgeRadius(delta);
        return true;
    }

}
