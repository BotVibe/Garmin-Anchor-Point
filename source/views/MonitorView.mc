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
        var cy = height / 2;

        if (_monitor.isDisplayOff()) {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.clear();
            return;
        }

        var dim = _monitor.isDisplayDim();
        var outside = _monitor.isOutside();
        var muted = _monitor.isAlarmMuted();

        var bg = outside ? Graphics.COLOR_DK_RED : Graphics.COLOR_BLACK;
        if (dim) {
            bg = Graphics.COLOR_BLACK;
        }
        dc.setColor(bg, bg);
        dc.clear();

        if (muted) {
            drawMutedScreen(dc, cx, cy, width, height, dim, outside);
            return;
        }

        var titleColor = dim ? Graphics.COLOR_DK_GRAY : Graphics.COLOR_WHITE;
        dc.setColor(titleColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height * 6 / 100, Graphics.FONT_TINY, WatchUi.loadResource(Rez.Strings.TitleMonitor) as String, Graphics.TEXT_JUSTIFY_CENTER);

        if (!_monitor.isAppActive()) {
            dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, height * 16 / 100, Graphics.FONT_XTINY, WatchUi.loadResource(Rez.Strings.HintInactive) as String, Graphics.TEXT_JUSTIFY_CENTER);
        }

        var statusColor = outside
            ? (dim ? Graphics.COLOR_ORANGE : Graphics.COLOR_YELLOW)
            : (dim ? Graphics.COLOR_DK_GREEN : Graphics.COLOR_GREEN);
        var statusText = outside
            ? (WatchUi.loadResource(Rez.Strings.StatusWarn) as String)
            : (WatchUi.loadResource(Rez.Strings.StatusOk) as String);
        dc.setColor(statusColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height * 28 / 100, Graphics.FONT_MEDIUM, statusText, Graphics.TEXT_JUSTIFY_CENTER);

        var bodyColor = dim ? Graphics.COLOR_LT_GRAY : Graphics.COLOR_WHITE;
        var dist = _monitor.getDistanceMeters();
        var distText = (WatchUi.loadResource(Rez.Strings.DistanceLabel) as String) + ": " + dist.format("%.0f") + " " + (WatchUi.loadResource(Rez.Strings.MetersUnit) as String);
        dc.setColor(bodyColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height * 44 / 100, Graphics.FONT_SMALL, distText, Graphics.TEXT_JUSTIFY_CENTER);

        var metaColor = dim ? Graphics.COLOR_DK_GRAY : Graphics.COLOR_LT_GRAY;
        var radiusText = (WatchUi.loadResource(Rez.Strings.RadiusLabel) as String) + ": " + _monitor.getRadiusMeters().toString() + " " + (WatchUi.loadResource(Rez.Strings.MetersUnit) as String);
        dc.setColor(metaColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height * 56 / 100, Graphics.FONT_TINY, radiusText, Graphics.TEXT_JUSTIFY_CENTER);

        var gpsText = WatchUi.loadResource(Geo.qualityStringId(_monitor.getAccuracy())) as String;
        dc.drawText(cx, height * 66 / 100, Graphics.FONT_XTINY, gpsText, Graphics.TEXT_JUSTIFY_CENTER);

        var elapsed = formatElapsed(_monitor.getElapsedSeconds());
        var runtimeText = (WatchUi.loadResource(Rez.Strings.RuntimeLabel) as String) + ": " + elapsed;
        dc.drawText(cx, height * 72 / 100, Graphics.FONT_XTINY, runtimeText, Graphics.TEXT_JUSTIFY_CENTER);

        dc.drawText(cx, height * 80 / 100, Graphics.FONT_XTINY, WatchUi.loadResource(Rez.Strings.HintMonitorMenu) as String, Graphics.TEXT_JUSTIFY_CENTER);
    }

    //! Fixed-column mute layout: status, ring+icon, distance, pause text, radius.
    private function drawMutedScreen(dc as Dc, cx as Number, cy as Number, width as Number, height as Number, dim as Boolean, outside as Boolean) as Void {
        var statusColor = outside
            ? (dim ? Graphics.COLOR_ORANGE : Graphics.COLOR_YELLOW)
            : (dim ? Graphics.COLOR_DK_GREEN : Graphics.COLOR_GREEN);
        var statusText = outside
            ? (WatchUi.loadResource(Rez.Strings.StatusWarn) as String)
            : (WatchUi.loadResource(Rez.Strings.StatusOk) as String);
        dc.setColor(statusColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height * 12 / 100, Graphics.FONT_TINY, statusText, Graphics.TEXT_JUSTIFY_CENTER);

        drawMuteRing(dc, cx, cy, width, height);
        drawMutedSpeakerIcon(dc, cx, cy);

        var metaColor = dim ? Graphics.COLOR_DK_GRAY : Graphics.COLOR_LT_GRAY;
        var dist = _monitor.getDistanceMeters();
        var distText = (WatchUi.loadResource(Rez.Strings.DistanceLabel) as String) + ": " + dist.format("%.0f") + " " + (WatchUi.loadResource(Rez.Strings.MetersUnit) as String);
        dc.setColor(metaColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height * 58 / 100, Graphics.FONT_XTINY, distText, Graphics.TEXT_JUSTIFY_CENTER);

        var remain = _monitor.getAlarmMuteRemainingSeconds();
        var mutedText = (WatchUi.loadResource(Rez.Strings.HintAlarmMuted) as String) + " " + remain.toString() + "s";
        dc.setColor(dim ? Graphics.COLOR_ORANGE : Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height * 68 / 100, Graphics.FONT_XTINY, mutedText, Graphics.TEXT_JUSTIFY_CENTER);

        var radiusText = (WatchUi.loadResource(Rez.Strings.RadiusLabel) as String) + ": " + _monitor.getRadiusMeters().toString() + " " + (WatchUi.loadResource(Rez.Strings.MetersUnit) as String);
        dc.setColor(metaColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height * 78 / 100, Graphics.FONT_XTINY, radiusText, Graphics.TEXT_JUSTIFY_CENTER);
    }

    //! Yellow countdown ring: full at mute start, depletes CCW from 12 o'clock.
    private function drawMuteRing(dc as Dc, cx as Number, cy as Number, width as Number, height as Number) as Void {
        var remaining = _monitor.getAlarmMuteRemainingSeconds();
        var total = _monitor.getAlarmMuteTotalSeconds();
        if ((total <= 0) || (remaining <= 0)) {
            return;
        }

        var radius = (width < height ? width : height) / 2 - 4;
        if (radius < 10) {
            radius = 10;
        }

        var fraction = (remaining * 1.0) / total;
        var sweep = (fraction * 360.0).toNumber();
        if (sweep < 1) {
            return;
        }

        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        if (dc has :setPenWidth) {
            dc.setPenWidth(3);
        }

        // Garmin arcs: degree 90 is 12 o'clock; deplete from there counterclockwise.
        var startDeg = 90 + ((1.0 - fraction) * 360.0).toNumber();
        dc.drawArc(cx, cy, radius, Graphics.ARC_COUNTER_CLOCKWISE, startDeg, startDeg + sweep);
    }

    //! Yellow muted-speaker icon (cone + slash) at center.
    private function drawMutedSpeakerIcon(dc as Dc, cx as Number, cy as Number) as Void {
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        if (dc has :setPenWidth) {
            dc.setPenWidth(2);
        }

        var bodyLeft = cx - 18;
        var bodyTop = cy - 8;
        dc.fillRectangle(bodyLeft, bodyTop, 10, 16);

        var coneLeft = bodyLeft + 10;
        dc.drawLine(coneLeft, bodyTop, cx + 10, cy - 18);
        dc.drawLine(cx + 10, cy - 18, cx + 10, cy + 18);
        dc.drawLine(cx + 10, cy + 18, coneLeft, bodyTop + 16);
        dc.drawLine(coneLeft, bodyTop, coneLeft, bodyTop + 16);

        if (dc has :setPenWidth) {
            dc.setPenWidth(3);
        }
        dc.drawLine(cx - 22, cy + 20, cx + 18, cy - 20);
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
