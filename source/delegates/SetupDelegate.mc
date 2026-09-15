import Toybox.Attention;
import Toybox.Lang;
import Toybox.WatchUi;

//! Input handling for the setup screen.
class SetupDelegate extends WatchUi.BehaviorDelegate {

    private var _monitor as AnchorMonitor;

    public function initialize(monitor as AnchorMonitor) {
        BehaviorDelegate.initialize();
        _monitor = monitor;
    }

    public function onSelect() as Boolean {
        return tryStart();
    }

    public function onKey(evt as KeyEvent) as Boolean {
        var key = evt.getKey();
        if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
            return tryStart();
        } else if (key == WatchUi.KEY_UP) {
            _monitor.nudgeRadius(1);
            return true;
        } else if (key == WatchUi.KEY_DOWN) {
            _monitor.nudgeRadius(-1);
            return true;
        }
        return false;
    }

    public function onPreviousPage() as Boolean {
        _monitor.nudgeRadius(1);
        return true;
    }

    public function onNextPage() as Boolean {
        _monitor.nudgeRadius(-1);
        return true;
    }

    public function onSwipe(evt as SwipeEvent) as Boolean {
        var direction = evt.getDirection();
        if (direction == WatchUi.SWIPE_UP) {
            _monitor.nudgeRadius(1);
            return true;
        } else if (direction == WatchUi.SWIPE_DOWN) {
            _monitor.nudgeRadius(-1);
            return true;
        }
        return false;
    }

    private function tryStart() as Boolean {
        if (_monitor.startMonitoring()) {
            WatchUi.switchToView(new $.MonitorView(_monitor), new $.MonitorDelegate(_monitor), WatchUi.SLIDE_LEFT);
        } else {
            if (Attention has :playTone) {
                Attention.playTone(Attention.TONE_ERROR);
            }
        }
        return true;
    }
}
