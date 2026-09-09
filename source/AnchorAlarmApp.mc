import Toybox.Application;
import Toybox.Lang;
import Toybox.Position;
import Toybox.WatchUi;

//! Anchor Alarm device app entry point.
class AnchorAlarmApp extends Application.AppBase {

    private var _monitor as AnchorMonitor?;

    //! Constructor
    public function initialize() {
        AppBase.initialize();
    }

    //! Enable continuous GPS when the app starts.
    //! @param state Startup arguments
    public function onStart(state as Dictionary?) as Void {
        _monitor = new $.AnchorMonitor();
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
    }

    //! Disable GPS and stop any open session.
    //! @param state Shutdown arguments
    public function onStop(state as Dictionary?) as Void {
        var monitor = _monitor;
        if (monitor != null) {
            if (!monitor.isSetup()) {
                monitor.stopMonitoring(false);
            }
        }
        Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
        _monitor = null;
    }

    //! Forward GPS updates to the monitor.
    //! @param info Position.Info
    public function onPosition(info as Info) as Void {
        var monitor = _monitor;
        if (monitor != null) {
            monitor.onPosition(info);
        }
    }

    //! @return Initial setup view and delegate
    public function getInitialView() as [Views] or [Views, InputDelegates] {
        var monitor = _monitor;
        if (monitor == null) {
            monitor = new $.AnchorMonitor();
            _monitor = monitor;
        }
        return [new $.SetupView(monitor), new $.SetupDelegate(monitor)];
    }

    //! Access the shared monitor instance.
    public function getMonitor() as AnchorMonitor? {
        return _monitor;
    }
}
