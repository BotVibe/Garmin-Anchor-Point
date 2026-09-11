import Toybox.Lang;
import Toybox.Test;

//! Run No Evil tests for radius preset helpers.
(:test)
function testRadiusPresetValues(logger as Logger) as Boolean {
    var values = RadiusPresets.values();
    Test.assertEqual(values.size(), 10);
    Test.assertEqual(values[0], 15);
    Test.assertEqual(values[1], 20);
    Test.assertEqual(values[7], 50);
    Test.assertEqual(values[8], 75);
    Test.assertEqual(values[9], 100);
    return true;
}

(:test)
function testRadiusSnapExactAndNearest(logger as Logger) as Boolean {
    Test.assertEqual(RadiusPresets.snap(50), 50);
    Test.assertEqual(RadiusPresets.snap(20), 20);
    Test.assertEqual(RadiusPresets.snap(22), 20);
    Test.assertEqual(RadiusPresets.snap(23), 25);
    Test.assertEqual(RadiusPresets.snap(60), 50);
    Test.assertEqual(RadiusPresets.snap(90), 100);
    Test.assertEqual(RadiusPresets.snap(1), 15);
    Test.assertEqual(RadiusPresets.snap(1000), 100);
    return true;
}

(:test)
function testRadiusNudgeWraps(logger as Logger) as Boolean {
    Test.assertEqual(RadiusPresets.nudgeIndex(0, -1), 9);
    Test.assertEqual(RadiusPresets.nudgeIndex(9, 1), 0);
    Test.assertEqual(RadiusPresets.nudgeIndex(7, 1), 8);
    Test.assertEqual(RadiusPresets.valueAt(RadiusPresets.nudgeIndex(7, 1)), 75);
    return true;
}
