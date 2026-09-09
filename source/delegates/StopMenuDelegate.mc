import Toybox.Lang;
import Toybox.WatchUi;

//! Menu actions when ending a monitoring session.
class StopMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _monitor as AnchorMonitor;

    //! @param monitor Shared monitor state
    public function initialize(monitor as AnchorMonitor) {
        Menu2InputDelegate.initialize();
        _monitor = monitor;
    }

    //! @param item Selected menu item
    public function onSelect(item as MenuItem) as Void {
        var id = item.getId();
        if (id == :save) {
            _monitor.stopMonitoring(true);
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            WatchUi.switchToView(new $.SetupView(_monitor), new $.SetupDelegate(_monitor), WatchUi.SLIDE_RIGHT);
        } else if (id == :discard) {
            _monitor.stopMonitoring(false);
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            WatchUi.switchToView(new $.SetupView(_monitor), new $.SetupDelegate(_monitor), WatchUi.SLIDE_RIGHT);
        } else {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
    }

    public function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
