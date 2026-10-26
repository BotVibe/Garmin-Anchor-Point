import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

//! Monitor view that opens the stop menu once onShow (smoke menu phase).
class SmokeMenuHostView extends WatchUi.View {

    private var _delegate as SmokeNavDelegate;
    private var _opened as Boolean = false;

    public function initialize(monitor as AnchorMonitor, delegate as SmokeNavDelegate) {
        View.initialize();
        _delegate = delegate;
    }

    public function onShow() as Void {
        if (!_opened) {
            _opened = true;
            _delegate.openMenu();
        }
    }

    public function onUpdate(dc as Dc) as Void {
        // Fallback fill if menu has not covered us yet.
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            dc.getWidth() / 2,
            dc.getHeight() / 2,
            Graphics.FONT_TINY,
            WatchUi.loadResource(Rez.Strings.TitleMonitor) as String,
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }
}
