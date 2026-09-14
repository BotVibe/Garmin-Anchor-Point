import Toybox.Graphics;
import Toybox.Lang;

//! Shared layout helpers so hint text stays readable on round displays.
module ViewLayout {

    //! Keep stacked hints above this fraction of screen height (round bezel).
    const SAFE_BOTTOM_FRACTION = 0.82;

    //! Line step for a hint font (font height + small gap).
    //! @param dc Device context
    //! @param font Graphics.FONT_* constant
    //! @return Pixel height per hint line
    function hintLineHeight(dc as Dc, font as Number) as Number {
        return dc.getFontHeight(font) + 2;
    }

    //! Cap a Y so the font baseline stays in the safe bottom zone.
    //! @param y Desired top Y for the line
    //! @param height Display height
    //! @param font Graphics.FONT_* constant
    //! @param dc Device context
    //! @return Clamped Y
    function clampBottomY(y as Number, height as Number, font as Number, dc as Dc) as Number {
        var maxY = (height * SAFE_BOTTOM_FRACTION).toNumber() - dc.getFontHeight(font);
        if (maxY < 0) {
            maxY = 0;
        }
        if (y > maxY) {
            return maxY;
        }
        return y;
    }

    //! Draw centered hint lines stacked downward from startY, staying above the safe bottom.
    //! @param dc Device context
    //! @param cx Center X
    //! @param startY First line Y
    //! @param font Graphics.FONT_* constant
    //! @param lines Array of String
    //! @return Y of the last drawn line
    function stackHintLines(dc as Dc, cx as Number, startY as Number, font as Number, lines as Array) as Number {
        var step = hintLineHeight(dc, font);
        var count = lines.size();
        var y = startY;
        if (count > 1) {
            var lastDesired = startY + (count - 1) * step;
            var lastSafe = clampBottomY(lastDesired, dc.getHeight(), font, dc);
            if (lastSafe < lastDesired) {
                y = lastSafe - (count - 1) * step;
                if (y < 0) {
                    y = 0;
                }
            }
        } else {
            y = clampBottomY(startY, dc.getHeight(), font, dc);
        }

        var i = 0;
        var lastY = y;
        while (i < count) {
            lastY = y;
            dc.drawText(cx, y, font, lines[i] as String, Graphics.TEXT_JUSTIFY_CENTER);
            y += step;
            i += 1;
        }
        return lastY;
    }
}
