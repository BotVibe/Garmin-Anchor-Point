import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

(:glance)
//! Compact glance preview in the watch glance list.
//! Tap opens the full watch-app; this view does not run GPS monitoring.
class AnchorGlanceView extends WatchUi.GlanceView {

    public function initialize() {
        GlanceView.initialize();
    }

    public function onUpdate(dc as Dc) as Void {
        var height = dc.getHeight();
        // Small left inset so glance text is not clipped by round-display chrome.
        var x = 2;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var titleFont = Graphics.FONT_TINY;
        if (Graphics has :FONT_GLANCE) {
            titleFont = Graphics.FONT_GLANCE;
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            x,
            height * 12 / 100,
            titleFont,
            WatchUi.loadResource(Rez.Strings.AppName) as String,
            Graphics.TEXT_JUSTIFY_LEFT
        );

        var radius = 50;
        var stored = Application.Properties.getValue("DefaultRadiusMeters");
        if (stored != null) {
            radius = stored as Number;
        }
        var detail = (WatchUi.loadResource(Rez.Strings.GlanceDetail) as String)
            + " "
            + radius.toString()
            + " "
            + (WatchUi.loadResource(Rez.Strings.MetersUnit) as String);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, height * 55 / 100, Graphics.FONT_XTINY, detail, Graphics.TEXT_JUSTIFY_LEFT);
    }
}
