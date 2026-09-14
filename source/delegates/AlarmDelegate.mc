import Toybox.Lang;
import Toybox.WatchUi;

//! Acknowledge, adjust radius, or end from the on-watch alarm.
class AlarmDelegate extends WatchUi.BehaviorDelegate {

    private var _monitor as AnchorMonitor;

    //! @param monitor Shared monitor state
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
        showStopMenu();
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
            showStopMenu();
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

    private function showStopMenu() as Void {
        var menu = new WatchUi.Menu2({:title => WatchUi.loadResource(Rez.Strings.MenuStopTitle) as String});
        menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.MenuEnd) as String, null, :end, null));
        menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.MenuCancel) as String, null, :cancel, null));
        WatchUi.pushView(menu, new $.StopMenuDelegate(_monitor), WatchUi.SLIDE_UP);
    }
}
