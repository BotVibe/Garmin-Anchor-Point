import Toybox.Lang;
import Toybox.Test;

//! Run No Evil tests for radius preset helpers.
(:test)
function testRadiusPresetValues(logger as Logger) as Boolean {
    var values = RadiusPresets.values();
    Test.assertEqual(values.size(), 5);
    Test.assertEqual(values[0], 15);
    Test.assertEqual(values[2], 50);
    Test.assertEqual(values[4], 100);
    return true;
}

(:test)
function testRadiusSnapExactAndNearest(logger as Logger) as Boolean {
    Test.assertEqual(RadiusPresets.snap(50), 50);
    Test.assertEqual(RadiusPresets.snap(20), 15);
    Test.assertEqual(RadiusPresets.snap(22), 25);
    Test.assertEqual(RadiusPresets.snap(60), 50);
    Test.assertEqual(RadiusPresets.snap(90), 100);
    Test.assertEqual(RadiusPresets.snap(1), 15);
    Test.assertEqual(RadiusPresets.snap(1000), 100);
    return true;
}

(:test)
function testRadiusNudgeWraps(logger as Logger) as Boolean {
    Test.assertEqual(RadiusPresets.nudgeIndex(0, -1), 4);
    Test.assertEqual(RadiusPresets.nudgeIndex(4, 1), 0);
    Test.assertEqual(RadiusPresets.nudgeIndex(2, 1), 3);
    Test.assertEqual(RadiusPresets.valueAt(RadiusPresets.nudgeIndex(2, 1)), 75);
    return true;
}
