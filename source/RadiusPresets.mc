import Toybox.Lang;

//! Supported anchor-radius presets and helpers.
module RadiusPresets {

    //! @return Radius choices in meters
    function values() as Array<Number> {
        return [15, 25, 50, 75, 100] as Array<Number>;
    }

    //! Snap an arbitrary meter value to the nearest preset.
    //! @param meters Desired radius
    //! @return Preset radius in meters
    function snap(meters as Number) as Number {
        return values()[indexOfNearest(meters)];
    }

    //! Index of the nearest preset for meters.
    //! @param meters Desired radius
    //! @return Index into values()
    function indexOfNearest(meters as Number) as Number {
        var options = values();
        var bestIndex = 0;
        var bestDiff = 100000;
        for (var i = 0; i < options.size(); i++) {
            var diff = meters - options[i];
            if (diff < 0) {
                diff = -diff;
            }
            if (diff < bestDiff) {
                bestDiff = diff;
                bestIndex = i;
            }
        }
        return bestIndex;
    }

    //! Move selection by delta with wrap-around.
    //! @param index Current index
    //! @param delta +1 / -1 (or other)
    //! @return New index
    function nudgeIndex(index as Number, delta as Number) as Number {
        var size = values().size();
        return (index + delta + size) % size;
    }

    //! @param index Preset index
    //! @return Radius meters for index (clamped)
    function valueAt(index as Number) as Number {
        var options = values();
        if (index < 0) {
            return options[0];
        }
        if (index >= options.size()) {
            return options[options.size() - 1];
        }
        return options[index];
    }
}
