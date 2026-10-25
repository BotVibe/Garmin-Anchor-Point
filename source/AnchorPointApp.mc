import Toybox.Application;
import Toybox.Lang;
import Toybox.Position;
import Toybox.WatchUi;

//! Anchor Point device app entry point.
class AnchorPointApp extends Application.AppBase {

    private var _monitor as AnchorMonitor?;

    public function initialize() {
        AppBase.initialize();
    }

    //! Glance and the full app share onStart/onStop. Keep these glance-safe:
    //! do not construct AnchorMonitor (or other non-(:glance) types) here, or the
    //! glance process crashes with "Class not available to 'Glance'".
    public function onStart(state as Dictionary?) as Void {
    }

    public function onStop(state as Dictionary?) as Void {
        // Tear down GPS only — session/timer cleanup lives in AnchorMonitor and is
        // invoked from the full-app stop menu before exit when monitoring.
        Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
        _monitor = null;
    }

    public function onPosition(info as Position.Info) as Void {
        var monitor = _monitor;
        if (monitor != null) {
            monitor.onPosition(info);
        }
    }

    public function getInitialView() as [Views] or [Views, InputDelegates] {
        var monitor = _monitor;
        if (monitor == null) {
            monitor = new $.AnchorMonitor();
            _monitor = monitor;
        }
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
        return [new $.SetupView(monitor), new $.SetupDelegate(monitor)];
    }

    (:glance)
    public function getGlanceView() as [WatchUi.GlanceView] or [WatchUi.GlanceView, WatchUi.GlanceViewDelegate] or Null {
        if (WatchUi has :GlanceView) {
            return [new $.AnchorGlanceView()];
        }
        return null;
    }

}
