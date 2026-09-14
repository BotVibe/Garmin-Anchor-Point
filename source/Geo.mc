import Toybox.Lang;
import Toybox.Math;
import Toybox.Position;
import Toybox.WatchUi;

//! Geographic helpers for anchor distance checks.
module Geo {

    //! Earth radius in meters.
    const EARTH_RADIUS_M = 6371000.0d;

    //! Compute great-circle distance in meters between two locations.
    //! @param a First location
    //! @param b Second location
    //! @return Distance in meters
    function distanceMeters(a as Location, b as Location) as Float {
        var ra = a.toRadians();
        var rb = b.toRadians();
        var lat1 = ra[0].toDouble();
        var lon1 = ra[1].toDouble();
        var lat2 = rb[0].toDouble();
        var lon2 = rb[1].toDouble();

        var dLat = lat2 - lat1;
        var dLon = lon2 - lon1;

        var sinDLat = Math.sin(dLat / 2.0d);
        var sinDLon = Math.sin(dLon / 2.0d);
        var h = (sinDLat * sinDLat)
            + (Math.cos(lat1) * Math.cos(lat2) * sinDLon * sinDLon);

        if (h < 0.0d) {
            h = 0.0d;
        } else if (h > 1.0d) {
            h = 1.0d;
        }

        var c = 2.0d * Math.atan2(Math.sqrt(h), Math.sqrt(1.0d - h));
        return (EARTH_RADIUS_M * c).toFloat();
    }

    //! Human-readable GPS quality label resource id.
    //! @param quality Position.QUALITY_* value
    //! @return ResourceId for a strings entry
    function qualityStringId(quality as Quality) as ResourceId {
        if (quality == Position.QUALITY_GOOD) {
            return Rez.Strings.GpsGood;
        } else if (quality == Position.QUALITY_USABLE) {
            return Rez.Strings.GpsOk;
        } else if (quality == Position.QUALITY_POOR) {
            return Rez.Strings.GpsPoor;
        } else if (quality == Position.QUALITY_LAST_KNOWN) {
            return Rez.Strings.GpsWaiting;
        }
        return Rez.Strings.GpsWaiting;
    }

    //! True when fix is good enough to set an anchor (highest quality only).
    //! @param quality Position.QUALITY_* value
    //! @return true only for QUALITY_GOOD
    function isFixGood(quality as Quality) as Boolean {
        return quality == Position.QUALITY_GOOD;
    }

    //! True when distance is strictly outside the allowed radius.
    //! @param distanceMeters Current distance from anchor
    //! @param radiusMeters Allowed radius
    //! @return true if breached
    function isOutsideRadius(distanceMeters as Float, radiusMeters as Number) as Boolean {
        return distanceMeters > radiusMeters.toFloat();
    }
}
