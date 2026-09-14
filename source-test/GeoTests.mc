import Toybox.Lang;
import Toybox.Position;
import Toybox.Test;

//! Run No Evil tests for geographic helpers.
(:test)
function testDistanceSamePoint(logger as Logger) as Boolean {
    var a = new Position.Location({:latitude => 54.0, :longitude => 10.0, :format => :degrees});
    var d = Geo.distanceMeters(a, a);
    logger.debug("same-point distance=" + d);
    Test.assertMessage(d < 1.0, "Expected ~0 m for identical points");
    return true;
}

(:test)
function testDistanceKnownOffset(logger as Logger) as Boolean {
    // ~111.2 km per degree latitude → 0.001 deg ≈ 111.2 m
    var a = new Position.Location({:latitude => 0.0, :longitude => 0.0, :format => :degrees});
    var b = new Position.Location({:latitude => 0.001, :longitude => 0.0, :format => :degrees});
    var d = Geo.distanceMeters(a, b);
    logger.debug("0.001 deg lat distance=" + d);
    Test.assertMessage((d > 100.0) && (d < 130.0), "Expected ~111 m for 0.001 deg latitude");
    return true;
}

(:test)
function testDistanceSymmetric(logger as Logger) as Boolean {
    var a = new Position.Location({:latitude => 53.55, :longitude => 9.99, :format => :degrees});
    var b = new Position.Location({:latitude => 53.56, :longitude => 10.01, :format => :degrees});
    var ab = Geo.distanceMeters(a, b);
    var ba = Geo.distanceMeters(b, a);
    var delta = ab - ba;
    if (delta < 0) {
        delta = -delta;
    }
    logger.debug("ab=" + ab + " ba=" + ba);
    Test.assertMessage(delta < 0.5, "Distance should be symmetric");
    return true;
}

(:test)
function testFixGoodRequiredToStart(logger as Logger) as Boolean {
    Test.assert(Geo.isFixGood(Position.QUALITY_GOOD));
    Test.assert(!Geo.isFixGood(Position.QUALITY_USABLE));
    Test.assert(!Geo.isFixGood(Position.QUALITY_POOR));
    Test.assert(!Geo.isFixGood(Position.QUALITY_LAST_KNOWN));
    Test.assert(!Geo.isFixGood(Position.QUALITY_NOT_AVAILABLE));
    return true;
}

(:test)
function testOutsideRadiusBoundary(logger as Logger) as Boolean {
    Test.assert(!Geo.isOutsideRadius(50.0, 50));
    Test.assert(!Geo.isOutsideRadius(49.9, 50));
    Test.assert(Geo.isOutsideRadius(50.1, 50));
    Test.assert(Geo.isOutsideRadius(100.0, 25));
    return true;
}

(:test)
function testQualityStringIds(logger as Logger) as Boolean {
    Test.assertEqual(Geo.qualityStringId(Position.QUALITY_GOOD), Rez.Strings.GpsGood);
    Test.assertEqual(Geo.qualityStringId(Position.QUALITY_USABLE), Rez.Strings.GpsOk);
    Test.assertEqual(Geo.qualityStringId(Position.QUALITY_POOR), Rez.Strings.GpsPoor);
    Test.assertEqual(Geo.qualityStringId(Position.QUALITY_NOT_AVAILABLE), Rez.Strings.GpsWaiting);
    return true;
}
