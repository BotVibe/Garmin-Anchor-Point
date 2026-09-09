import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Position;
import Toybox.WatchUi;

//! Initial screen: GPS status, radius, set anchor & start.
class SetupView extends WatchUi.View {

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

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height * 8 / 100, Graphics.FONT_SMALL, WatchUi.loadResource(Rez.Strings.TitleSetup) as String, Graphics.TEXT_JUSTIFY_CENTER);

        var gpsText = WatchUi.loadResource(Geo.qualityStringId(_monitor.getAccuracy())) as String;
        var gpsColor = Graphics.COLOR_LT_GRAY;
        if (Geo.isFixUsable(_monitor.getAccuracy())) {
            gpsColor = Graphics.COLOR_GREEN;
        } else if (_monitor.getAccuracy() == Position.QUALITY_POOR) {
            gpsColor = Graphics.COLOR_YELLOW;
        } else {
            gpsColor = Graphics.COLOR_ORANGE;
        }
        dc.setColor(gpsColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height * 22 / 100, Graphics.FONT_TINY, gpsText, Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        var radiusLine = (WatchUi.loadResource(Rez.Strings.RadiusLabel) as String) + ": " + _monitor.getRadiusMeters().toString() + " " + (WatchUi.loadResource(Rez.Strings.MetersUnit) as String);
        dc.drawText(cx, height * 38 / 100, Graphics.FONT_MEDIUM, radiusLine, Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height * 58 / 100, Graphics.FONT_XTINY, WatchUi.loadResource(Rez.Strings.HintChangeRadius) as String, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx, height * 70 / 100, Graphics.FONT_XTINY, WatchUi.loadResource(Rez.Strings.HintSetAnchor) as String, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx, height * 82 / 100, Graphics.FONT_XTINY, WatchUi.loadResource(Rez.Strings.HintKeepOpen) as String, Graphics.TEXT_JUSTIFY_CENTER);
    }
}
