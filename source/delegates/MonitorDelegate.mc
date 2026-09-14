import Toybox.Lang;
import Toybox.WatchUi;

//! Input handling for the monitoring screen.
class MonitorDelegate extends WatchUi.BehaviorDelegate {

    private var _monitor as AnchorMonitor;

    //! @param monitor Shared monitor state
    public function initialize(monitor as AnchorMonitor) {
        BehaviorDelegate.initialize();
        _monitor = monitor;
    }

    public function onMenu() as Boolean {
        if (wakeIfDisplayOff()) {
            return true;
        }
        _monitor.resetDisplayIdle();
        showStopMenu();
        return true;
    }

    public function onKey(evt as KeyEvent) as Boolean {
        if (wakeIfDisplayOff()) {
            return true;
        }
        var key = evt.getKey();
        if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
            _monitor.resetDisplayIdle();
            showStopMenu();
            return true;
        } else if (key == WatchUi.KEY_UP) {
            _monitor.nudgeRadius(1);
            return true;
        } else if (key == WatchUi.KEY_DOWN) {
            _monitor.nudgeRadius(-1);
            return true;
        } else if (key == WatchUi.KEY_ESC) {
            _monitor.resetDisplayIdle();
            showStopMenu();
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
        showStopMenu();
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

    //! First interaction while off only wakes the display.
    //! @return true if the event was consumed as a wake
    private function wakeIfDisplayOff() as Boolean {
        if (_monitor.isDisplayOff()) {
            _monitor.resetDisplayIdle();
            return true;
        }
        return false;
    }

    private function showStopMenu() as Void {
        var menu = new WatchUi.Menu2({:title => WatchUi.loadResource(Rez.Strings.MenuStopTitle) as String});
        menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.MenuEnd) as String, null, :end, null));
        menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.MenuCancel) as String, null, :cancel, null));
        WatchUi.pushView(menu, new $.StopMenuDelegate(_monitor), WatchUi.SLIDE_UP);
    }
}
