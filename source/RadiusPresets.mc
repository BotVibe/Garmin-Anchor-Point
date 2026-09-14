import Toybox.Lang;

//! Supported anchor-radius presets and helpers.
module RadiusPresets {

    function values() as Array<Number> {
        return [15, 20, 25, 30, 35, 40, 45, 50, 75, 100] as Array<Number>;
    }

    function snap(meters as Number) as Number {
        return values()[indexOfNearest(meters)];
    }

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

    function nudgeIndex(index as Number, delta as Number) as Number {
        var size = values().size();
        return (index + delta + size) % size;
    }

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
