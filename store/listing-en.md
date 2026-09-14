# Connect IQ Store listing (English)

Copy these fields into the Connect IQ Store submission form. Keep the tone factual and scoped to the watch-only MVP.

**Live Store page:** https://apps.garmin.com/en-US/apps/db28a9a5-5c3f-4c0a-a5cd-fae895c40d0d  
**Source repo:** https://github.com/BotVibe/Garmin-Anchor-Point

## App name

Anchor Point

## Short description (≤ 255 characters)

Watch-only GPS anchor alarm for boaters. Set an anchor point, choose a radius, and get a tone/vibrate alert on the watch if the boat drifts out of range.

## Long description

Anchor Point helps you notice when your boat drifts away from the spot you anchored.

How it works:

1. Wait for a **good** GPS fix on your watch (highest quality; “GPS OK” alone is not enough).
2. Choose an alert radius (15–50 m in 5 m steps, plus 75 m and 100 m).
3. Start monitoring from the apps list or by tapping the Anchor Point glance. The watch stores the current position as the anchor.
4. While monitoring, the watch shows distance to the anchor and whether you are inside or outside the radius.
5. If the boat drifts outside the radius, the watch alarms with tone and/or vibration according to your setting.
6. From the alarm screen you can silence for 60 seconds (display stays on with a mute icon and countdown ring), enlarge the radius with UP/DOWN, or open the menu to **Stop surveillance** or **Continue surveillance**.
7. Choose **Stop surveillance** when you are done (or **Continue surveillance** to keep monitoring).

While monitoring, the display dims after 30 seconds of inactivity and turns off after 10 more seconds; tap or press a button to wake it. During an active alarm or the 60-second silence period the display stays fully on. The glance is a launch shortcut only — monitoring requires the full app to stay open.

Alarm style (Connect IQ settings):

- Tone + vibrate (default)
- Tone only
- Vibrate only

What this app does not do (MVP):

- No phone companion app
- No internet or remote alerts
- No chart plotting or navigation features
- No activity / FIT recording
- No background monitoring while the app is closed

Important: GPS quality can vary. Use this as a secondary awareness aid, not as your only safety system.

Source code, documentation, and issue tracker:
https://github.com/BotVibe/Garmin-Anchor-Point

## Category

Suggested: Safety / Sports (Boating) — choose the closest available Connect IQ category for watch apps.

## Keywords / tags

anchor, boat, drift, GPS, marine, safety, watch alarm, glance

## What’s new (for this release)

- Fixed mute-screen text overlap on round displays (clearer column layout)
- Hardened against IQ! crashes from backlight refresh during mute/alarm
- Glance entry: open from the glance list or the apps list
- Start monitoring only with GPS good (highest quality)
- Mute UI with countdown ring; 60 s silence while outside
- Display idle: dim after 30 s, off after 10 s more (full during alarm/mute)
- Stop menu: Stop surveillance / Continue surveillance
- Radius presets: 15–50 m (5 m steps), 75 m, 100 m
- Alarm style setting: tone+vibrate, tone only, or vibrate only
- No FIT / activity recording

## Support / contact

Source / docs: https://github.com/BotVibe/Garmin-Anchor-Point

Bug reports and feature requests:
https://github.com/BotVibe/Garmin-Anchor-Point/issues

## Privacy policy URL

Host `store/privacy-en.md` (or an equivalent page) publicly and paste that URL into the store form.
For a quick public URL from this repository, you can use the raw GitHub file link after publishing the file on the default branch.
