import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

(:glance)
//! Compact glance preview in the watch glance list.
//! Tap opens the full watch-app; this view does not run GPS monitoring.
//! Two-line detail (hint + radius) so venu3's narrow glance strip does not clip.
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
            height * 8 / 100,
            titleFont,
            WatchUi.loadResource(Rez.Strings.AppName) as String,
            Graphics.TEXT_JUSTIFY_LEFT
        );

        var radius = 50;
        var stored = Application.Properties.getValue("DefaultRadiusMeters");
        if (stored != null) {
            radius = stored as Number;
        }
        var hint = WatchUi.loadResource(Rez.Strings.GlanceDetail) as String;
        var radiusLine = radius.toString()
            + " "
            + (WatchUi.loadResource(Rez.Strings.MetersUnit) as String);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, height * 48 / 100, Graphics.FONT_XTINY, hint, Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(x, height * 72 / 100, Graphics.FONT_XTINY, radiusLine, Graphics.TEXT_JUSTIFY_LEFT);
    }
}
