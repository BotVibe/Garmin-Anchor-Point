import Toybox.Lang;
import Toybox.WatchUi;

//! Applies one UI-smoke phase. Phase selected via SmokePhase.PHASE at build time.
//! 0=setup 1=inside 2=outside 3=alarm 4=mute 5=menu
class SmokeNavDelegate extends WatchUi.BehaviorDelegate {

    private var _monitor as AnchorMonitor;

    public function initialize(monitor as AnchorMonitor) {
        BehaviorDelegate.initialize();
        _monitor = monitor;
    }

    //! Seed session + return the view for this phase (used from getInitialView).
    public function applyPhaseToView(phase as Number) as WatchUi.Views {
        _monitor.smokePrepare();
        if (phase == 0) {
            _monitor.smokeSession().seedSetupGoodGps();
            return new $.SetupView(_monitor);
        } else if (phase == 1) {
            _monitor.smokeSession().seedMonitoringInside();
            _monitor.smokeArmDisplay(false);
            return new $.MonitorView(_monitor);
        } else if (phase == 2) {
            _monitor.smokeSession().seedMonitoringOutside();
            _monitor.smokeArmDisplay(true);
            return new $.MonitorView(_monitor);
        } else if (phase == 3) {
            _monitor.smokeSession().seedAlarmOutside();
            _monitor.smokeMarkAlarmPushed();
            return new $.AlarmView(_monitor);
        } else if (phase == 4) {
            _monitor.smokeSession().seedMutedOutside();
            _monitor.smokeArmDisplay(true);
            return new $.MonitorView(_monitor);
        } else {
            _monitor.smokeSession().seedMonitoringInside();
            _monitor.smokeArmDisplay(false);
            // Push menu after the monitor view is shown — caller uses onLayout/onShow.
            // Return monitor; open menu from onShow via a one-shot.
            return new $.SmokeMenuHostView(_monitor, self);
        }
    }

    public function openMenu() as Void {
        _monitor.openStopMenu();
    }

    public function onSelect() as Boolean {
        return true;
    }

    public function onKey(evt as KeyEvent) as Boolean {
        return true;
    }

    public function onTap(evt as ClickEvent) as Boolean {
        return true;
    }
}
