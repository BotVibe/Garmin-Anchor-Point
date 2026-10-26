import Toybox.Lang;
import Toybox.Test;
import Toybox.WatchUi;

//! Ensure every Rez string used by UI/settings resolves (non-empty) in the
//! active simulator/device language. Run once per language after switching
//! Settings → Language and reloading the test PRG.
(:test)
function testAllUiStringsResolve(logger as Logger) as Boolean {
    var ids = [
        Rez.Strings.AppName,
        Rez.Strings.AppVersion,
        Rez.Strings.TitleSetup,
        Rez.Strings.TitleMonitor,
        Rez.Strings.TitleAlarm,
        Rez.Strings.GpsWaiting,
        Rez.Strings.GpsPoor,
        Rez.Strings.GpsOk,
        Rez.Strings.GpsGood,
        Rez.Strings.GpsUnknown,
        Rez.Strings.RadiusLabel,
        Rez.Strings.MetersUnit,
        Rez.Strings.SecondsUnit,
        Rez.Strings.DistanceLabel,
        Rez.Strings.StatusOk,
        Rez.Strings.StatusWarn,
        Rez.Strings.RuntimeLabel,
        Rez.Strings.HintSetAnchor,
        Rez.Strings.HintChangeRadius,
        Rez.Strings.HintKeepOpen,
        Rez.Strings.HintMonitorMenu,
        Rez.Strings.HintAlarmAck,
        Rez.Strings.HintAlarmRadius,
        Rez.Strings.HintAlarmMenu,
        Rez.Strings.HintAlarmMuted,
        Rez.Strings.MenuStopTitle,
        Rez.Strings.MenuEnd,
        Rez.Strings.MenuCancel,
        Rez.Strings.MenuRadius,
        Rez.Strings.AlarmBody,
        Rez.Strings.NeedGps,
        Rez.Strings.AnchorSet,
        Rez.Strings.GlanceDetail,
        Rez.Strings.SettingRadiusTitle,
        Rez.Strings.Radius15,
        Rez.Strings.Radius20,
        Rez.Strings.Radius25,
        Rez.Strings.Radius30,
        Rez.Strings.Radius35,
        Rez.Strings.Radius40,
        Rez.Strings.Radius45,
        Rez.Strings.Radius50,
        Rez.Strings.Radius75,
        Rez.Strings.Radius100,
        Rez.Strings.SettingAlarmModeTitle,
        Rez.Strings.AlarmModeBoth,
        Rez.Strings.AlarmModeTone,
        Rez.Strings.AlarmModeVibrate
    ];

    var i = 0;
    while (i < ids.size()) {
        var s = WatchUi.loadResource(ids[i]) as String;
        if (s == null || s.length() == 0) {
            logger.error("Empty or missing string at index " + i);
            return false;
        }
        i++;
    }
    logger.debug("Resolved " + ids.size() + " UI/settings strings");
    return true;
}
