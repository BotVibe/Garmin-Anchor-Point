import Toybox.Lang;
import Toybox.Position;
import Toybox.Test;

//! Enable by adding source-test to monkey.jungle and building with monkeyc -t.
(:test)
function testDistanceSamePoint(logger as Logger) as Boolean {
    var a = new Position.Location({:latitude => 54.0, :longitude => 10.0, :format => :degrees});
    var d = Geo.distanceMeters(a, a);
    logger.debug("same-point distance=" + d);
    return d < 1.0;
}

(:test)
function testDistanceKnownOffset(logger as Logger) as Boolean {
    var a = new Position.Location({:latitude => 0.0, :longitude => 0.0, :format => :degrees});
    var b = new Position.Location({:latitude => 0.001, :longitude => 0.0, :format => :degrees});
    var d = Geo.distanceMeters(a, b);
    logger.debug("0.001 deg distance=" + d);
    return (d > 100.0) && (d < 130.0);
}

(:test)
function testFixUsable(logger as Logger) as Boolean {
    return Geo.isFixUsable(Position.QUALITY_USABLE)
        && Geo.isFixUsable(Position.QUALITY_GOOD)
        && !Geo.isFixUsable(Position.QUALITY_POOR)
        && !Geo.isFixUsable(Position.QUALITY_NOT_AVAILABLE);
}
