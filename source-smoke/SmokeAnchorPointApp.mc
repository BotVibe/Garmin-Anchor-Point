import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

//! Smoke-only app entry (smoke-manifest.xml / smoke.jungle). Cycles deterministic
//! UI states via START/Enter so an external script can screenshot each screen.
//! Not included in release builds (monkey.jungle excludes source-smoke/).
class SmokeAnchorPointApp extends Application.AppBase {

    public function initialize() {
        AppBase.initialize();
    }

    public function onStart(state as Dictionary?) as Void {
    }

    public function onStop(state as Dictionary?) as Void {
    }

    public function getInitialView() as [Views] or [Views, InputDelegates] {
        var monitor = new $.AnchorMonitor();
        monitor.smokeSession().seedSetupGoodGps();
        var delegate = new $.SmokeNavDelegate(monitor);
        return [new $.SetupView(monitor), delegate];
    }

    (:glance)
    public function getGlanceView() as [WatchUi.GlanceView] or [WatchUi.GlanceView, WatchUi.GlanceViewDelegate] or Null {
        if (WatchUi has :GlanceView) {
            return [new $.AnchorGlanceView()];
        }
        return null;
    }
}
