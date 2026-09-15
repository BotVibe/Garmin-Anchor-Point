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

    public function onStart(state as Dictionary?) as Void {
        _monitor = new $.AnchorMonitor();
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
    }

    public function onStop(state as Dictionary?) as Void {
        var monitor = _monitor;
        if (monitor != null) {
            if (!monitor.isSetup()) {
                monitor.stopMonitoring();
            }
        }
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
