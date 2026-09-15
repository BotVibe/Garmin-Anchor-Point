import Toybox.Lang;
import Toybox.WatchUi;

//! Menu actions when ending a monitoring session.
class StopMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _monitor as AnchorMonitor;

    public function initialize(monitor as AnchorMonitor) {
        Menu2InputDelegate.initialize();
        _monitor = monitor;
    }

    public function onSelect(item as MenuItem) as Void {
        var id = item.getId();
        if (id == :end) {
            var popAlarm = _monitor.isAlarmViewPushed();
            _monitor.stopMonitoring();
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            if (popAlarm) {
                WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            }
            WatchUi.switchToView(new $.SetupView(_monitor), new $.SetupDelegate(_monitor), WatchUi.SLIDE_RIGHT);
        } else {
            _monitor.resetDisplayIdle();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
    }

    public function onBack() as Void {
        _monitor.resetDisplayIdle();
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
