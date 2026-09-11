import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

//! Live monitoring screen while the anchor session is active.
class MonitorView extends WatchUi.View {

    private var _monitor as AnchorMonitor;

    //! @param monitor Shared monitor state
    public function initialize(monitor as AnchorMonitor) {
        View.initialize();
        _monitor = monitor;
    }

    //! @param dc Device context
    public function onUpdate(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var cx = width / 2;

        var outside = _monitor.isOutside();
        var bg = outside ? Graphics.COLOR_DK_RED : Graphics.COLOR_BLACK;
        dc.setColor(bg, bg);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height * 6 / 100, Graphics.FONT_TINY, WatchUi.loadResource(Rez.Strings.TitleMonitor) as String, Graphics.TEXT_JUSTIFY_CENTER);

        if (!_monitor.isAppActive()) {
            dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, height * 16 / 100, Graphics.FONT_XTINY, WatchUi.loadResource(Rez.Strings.HintInactive) as String, Graphics.TEXT_JUSTIFY_CENTER);
        }

        var statusColor = outside ? Graphics.COLOR_YELLOW : Graphics.COLOR_GREEN;
        var statusText = outside
            ? (WatchUi.loadResource(Rez.Strings.StatusWarn) as String)
            : (WatchUi.loadResource(Rez.Strings.StatusOk) as String);
        dc.setColor(statusColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height * 28 / 100, Graphics.FONT_MEDIUM, statusText, Graphics.TEXT_JUSTIFY_CENTER);

        var dist = _monitor.getDistanceMeters();
        var distText = (WatchUi.loadResource(Rez.Strings.DistanceLabel) as String) + ": " + dist.format("%.0f") + " " + (WatchUi.loadResource(Rez.Strings.MetersUnit) as String);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height * 44 / 100, Graphics.FONT_SMALL, distText, Graphics.TEXT_JUSTIFY_CENTER);

        var radiusText = (WatchUi.loadResource(Rez.Strings.RadiusLabel) as String) + ": " + _monitor.getRadiusMeters().toString() + " " + (WatchUi.loadResource(Rez.Strings.MetersUnit) as String);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height * 56 / 100, Graphics.FONT_TINY, radiusText, Graphics.TEXT_JUSTIFY_CENTER);

        var gpsText = WatchUi.loadResource(Geo.qualityStringId(_monitor.getAccuracy())) as String;
        dc.drawText(cx, height * 66 / 100, Graphics.FONT_XTINY, gpsText, Graphics.TEXT_JUSTIFY_CENTER);

        var elapsed = formatElapsed(_monitor.getElapsedSeconds());
        var runtimeText = (WatchUi.loadResource(Rez.Strings.RuntimeLabel) as String) + ": " + elapsed;
        dc.drawText(cx, height * 76 / 100, Graphics.FONT_XTINY, runtimeText, Graphics.TEXT_JUSTIFY_CENTER);

        if (_monitor.isAlarmMuted() && outside) {
            var muted = (WatchUi.loadResource(Rez.Strings.HintAlarmMuted) as String) + " " + _monitor.getAlarmMuteRemainingSeconds().toString() + "s";
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, height * 88 / 100, Graphics.FONT_XTINY, muted, Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.drawText(cx, height * 88 / 100, Graphics.FONT_XTINY, WatchUi.loadResource(Rez.Strings.HintMonitorMenu) as String, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    //! Format seconds as h:mm:ss or m:ss.
    //! @param totalSeconds Elapsed seconds
    //! @return Formatted string
    private function formatElapsed(totalSeconds as Number) as String {
        var hours = totalSeconds / 3600;
        var minutes = (totalSeconds % 3600) / 60;
        var seconds = totalSeconds % 60;
        if (hours > 0) {
            return hours.toString() + ":" + pad2(minutes) + ":" + pad2(seconds);
        }
        return minutes.toString() + ":" + pad2(seconds);
    }

    //! @param value Non-negative integer
    //! @return Two-digit zero-padded string
    private function pad2(value as Number) as String {
        if (value < 10) {
            return "0" + value.toString();
        }
        return value.toString();
    }
}
