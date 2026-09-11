import Toybox.Lang;
import Toybox.Position;
import Toybox.Test;

//! Run No Evil tests for the pure monitoring state machine.
(:test)
function testSessionStartsOnlyWithUsableFix(logger as Logger) as Boolean {
    var session = new AnchorSession();
    var loc = new Position.Location({:latitude => 54.0, :longitude => 10.0, :format => :degrees});

    session.updateLocation(loc, Position.QUALITY_POOR);
    Test.assert(!session.startMonitoring());
    Test.assert(session.isSetup());

    session.updateLocation(loc, Position.QUALITY_USABLE);
    Test.assert(session.startMonitoring());
    Test.assert(session.isMonitoring());
    Test.assertEqual(session.getRadiusMeters(), 50);
    Test.assert(!session.isOutside());
    return true;
}

(:test)
function testSessionBreachesRadiusAndAlarms(logger as Logger) as Boolean {
    var session = new AnchorSession();
    session.setRadiusMeters(50);

    var anchor = new Position.Location({:latitude => 0.0, :longitude => 0.0, :format => :degrees});
    // ~111 m north — outside 50 m
    var outside = new Position.Location({:latitude => 0.001, :longitude => 0.0, :format => :degrees});

    session.updateLocation(anchor, Position.QUALITY_GOOD);
    Test.assert(session.startMonitoring());

    var entered = session.updateLocation(outside, Position.QUALITY_GOOD);
    logger.debug("distance=" + session.getDistanceMeters() + " outside=" + session.isOutside());
    Test.assert(entered);
    Test.assert(session.isAlarming());
    Test.assert(session.isOutside());
    Test.assert(session.getDistanceMeters() > 50.0);
    return true;
}

(:test)
function testSessionStaysInsideSmallMove(logger as Logger) as Boolean {
    var session = new AnchorSession();
    session.setRadiusMeters(100);

    var anchor = new Position.Location({:latitude => 0.0, :longitude => 0.0, :format => :degrees});
    // ~11 m north — inside 100 m
    var near = new Position.Location({:latitude => 0.0001, :longitude => 0.0, :format => :degrees});

    session.updateLocation(anchor, Position.QUALITY_GOOD);
    Test.assert(session.startMonitoring());

    var entered = session.updateLocation(near, Position.QUALITY_GOOD);
    logger.debug("distance=" + session.getDistanceMeters());
    Test.assert(!entered);
    Test.assert(session.isMonitoring());
    Test.assert(!session.isOutside());
    Test.assert(session.getDistanceMeters() < 20.0);
    return true;
}

(:test)
function testAcknowledgeAndRearmWhileOutside(logger as Logger) as Boolean {
    var session = new AnchorSession();
    session.setRadiusMeters(25);

    var anchor = new Position.Location({:latitude => 0.0, :longitude => 0.0, :format => :degrees});
    var outside = new Position.Location({:latitude => 0.001, :longitude => 0.0, :format => :degrees});

    session.updateLocation(anchor, Position.QUALITY_GOOD);
    Test.assert(session.startMonitoring());
    Test.assert(session.updateLocation(outside, Position.QUALITY_GOOD));
    Test.assert(session.isAlarming());

    session.acknowledgeAlarm();
    Test.assert(session.isMonitoring());

    Test.assert(session.rearmIfStillOutside());
    Test.assert(session.isAlarming());
    return true;
}

(:test)
function testAcknowledgeClearsWhenBackInside(logger as Logger) as Boolean {
    var session = new AnchorSession();
    session.setRadiusMeters(50);

    var anchor = new Position.Location({:latitude => 0.0, :longitude => 0.0, :format => :degrees});
    var outside = new Position.Location({:latitude => 0.001, :longitude => 0.0, :format => :degrees});

    session.updateLocation(anchor, Position.QUALITY_GOOD);
    Test.assert(session.startMonitoring());
    Test.assert(session.updateLocation(outside, Position.QUALITY_GOOD));

    session.acknowledgeAlarm();
    // Move back to anchor before rearm check
    session.updateLocation(anchor, Position.QUALITY_GOOD);
    Test.assert(!session.rearmIfStillOutside());
    Test.assert(session.isMonitoring());
    Test.assert(!session.isOutside());
    return true;
}

(:test)
function testStopReturnsToSetup(logger as Logger) as Boolean {
    var session = new AnchorSession();
    var loc = new Position.Location({:latitude => 54.1, :longitude => 10.2, :format => :degrees});
    session.updateLocation(loc, Position.QUALITY_GOOD);
    Test.assert(session.startMonitoring());
    session.stopMonitoring();
    Test.assert(session.isSetup());
    Test.assert(session.getAnchorLocation() == null);
    Test.assertEqual(session.getElapsedSeconds(), 0);
    return true;
}

(:test)
function testNudgeRadiusChangesPreset(logger as Logger) as Boolean {
    var session = new AnchorSession();
    session.setRadiusMeters(50);
    Test.assertEqual(session.getRadiusMeters(), 50);
    session.nudgeRadius(1);
    Test.assertEqual(session.getRadiusMeters(), 75);
    session.nudgeRadius(-1);
    Test.assertEqual(session.getRadiusMeters(), 50);
    session.nudgeRadius(-1);
    Test.assertEqual(session.getRadiusMeters(), 45);
    return true;
}

(:test)
function testLargerRadiusCanClearOutsideFlag(logger as Logger) as Boolean {
    var session = new AnchorSession();
    session.setRadiusMeters(25);

    var anchor = new Position.Location({:latitude => 0.0, :longitude => 0.0, :format => :degrees});
    var mid = new Position.Location({:latitude => 0.0005, :longitude => 0.0, :format => :degrees}); // ~55 m

    session.updateLocation(anchor, Position.QUALITY_GOOD);
    Test.assert(session.startMonitoring());
    Test.assert(session.updateLocation(mid, Position.QUALITY_GOOD));
    Test.assert(session.isOutside());

    session.acknowledgeAlarm();
    session.setRadiusMeters(100);
    Test.assert(!session.isOutside());
    Test.assert(!session.rearmIfStillOutside());
    Test.assert(session.isMonitoring());
    return true;
}
