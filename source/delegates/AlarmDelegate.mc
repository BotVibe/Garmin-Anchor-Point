import Toybox.Lang;
import Toybox.WatchUi;

//! Acknowledge or dismiss the on-watch alarm.
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

    public function onKey(evt as KeyEvent) as Boolean {
        var key = evt.getKey();
        if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START || key == WatchUi.KEY_ESC) {
            return acknowledge();
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
}
