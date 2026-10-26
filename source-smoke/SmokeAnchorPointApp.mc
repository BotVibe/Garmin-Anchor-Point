import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

//! Smoke-only app entry (smoke-manifest.xml / smoke.jungle).
//! Shows one seeded UI state from SmokePhase.PHASE (no auto-advance).
//! Intentionally omits getGlanceView so monkeydo opens getInitialView directly
//! (no flaky glance double-click). Glance screenshots use the release PRG.
//! Not included in release builds.
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
        var delegate = new $.SmokeNavDelegate(monitor);
        var view = delegate.applyPhaseToView($.SmokePhase.PHASE);
        return [view, delegate];
    }
}
