import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

//! Full-screen alarm while the boat is outside the radius.
class AlarmView extends WatchUi.View {

    private var _monitor as AnchorMonitor;

    //! @param monitor Shared monitor state
    public function initialize(monitor as AnchorMonitor) {
        View.initialize();
        _monitor = monitor;
    }

    public function onHide() as Void {
        _monitor.onAlarmViewClosed();
    }

    //! @param dc Device context
    public function onUpdate(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var cx = width / 2;

        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height * 18 / 100, Graphics.FONT_LARGE, WatchUi.loadResource(Rez.Strings.TitleAlarm) as String, Graphics.TEXT_JUSTIFY_CENTER);

        dc.drawText(cx, height * 40 / 100, Graphics.FONT_SMALL, WatchUi.loadResource(Rez.Strings.AlarmBody) as String, Graphics.TEXT_JUSTIFY_CENTER);

        var dist = _monitor.getDistanceMeters();
        var distText = (WatchUi.loadResource(Rez.Strings.DistanceLabel) as String) + ": " + dist.format("%.0f") + " " + (WatchUi.loadResource(Rez.Strings.MetersUnit) as String);
        dc.drawText(cx, height * 58 / 100, Graphics.FONT_TINY, distText, Graphics.TEXT_JUSTIFY_CENTER);

        var radiusText = (WatchUi.loadResource(Rez.Strings.RadiusLabel) as String) + ": " + _monitor.getRadiusMeters().toString() + " " + (WatchUi.loadResource(Rez.Strings.MetersUnit) as String);
        dc.drawText(cx, height * 70 / 100, Graphics.FONT_XTINY, radiusText, Graphics.TEXT_JUSTIFY_CENTER);

        dc.drawText(cx, height * 86 / 100, Graphics.FONT_XTINY, WatchUi.loadResource(Rez.Strings.HintAlarmAck) as String, Graphics.TEXT_JUSTIFY_CENTER);
    }
}
