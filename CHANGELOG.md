# Changelog

All notable changes to Anchor Point are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.1.1] - 2026-09-14

### Fixed
- Mute screen overlap: fixed-column layout (status → ring/icon → distance → pause countdown → radius) so text no longer stacks on top of itself on round displays
- IQ! crash hardening: `Attention.backlight` only on on/off state changes (no per-second refresh during mute/force-full; alarm pulse no longer re-asserts backlight)

### Changed
- Removed `ViewLayout` helper; setup/alarm/monitor hints use fixed Y positions
- Dim uses darker text colors only (no dense overlay line loop); unused muted-speaker bitmap removed

## [2.1.0] - 2026-09-14

### Added
- Mute UI: yellow muted-speaker icon and countdown ring (depletes counterclockwise from 12 o'clock) while the alarm is silenced
- Monitoring display idle: full brightness for 30 s, then dim, then black after 10 s more; wake on tap/controls (mute and active alarm keep full brightness)
- Glance entry: app appears in the watch glance list; tap opens the full watch-app (monitoring still requires the app to stay open)
- Fresh Connect IQ Store screenshots and promo banner for 2.1.0

### Changed
- Shortened on-watch hint labels (setup/alarm/monitor) and raised them so round displays (e.g. Forerunner 965) show the full text
- Monitoring can start only when GPS quality is `QUALITY_GOOD` (not merely `QUALITY_USABLE`)
- Stop menu wording: Stop surveillance / Continue surveillance
- Store listing and README cross-link the GitHub repo and the Connect IQ Store page
- Docs pass: README/AGENTS/store listing aligned with current product behavior

## [2.0.0] - 2026-09-11

### Added
- Radius presets in 5 m steps from 15–50 m (plus 75 / 100 m)
- Alarm style setting: tone + vibrate, tone only, or vibrate only
- 60 s alarm snooze after acknowledge so radius can be adjusted or the session ended while still outside
- Alarm screen controls: UP/DOWN change radius; MENU ends the session; enlarging enough to be inside clears the alarm

### Changed
- End-session menu is End / Cancel only (no Save / Discard)
- Store listing, privacy text, README, and AGENTS.md updated for the new behavior

### Removed
- FIT / activity recording and the Fit permission (monitoring is GPS-only)

### Fixed
- Unusable short window to silence the alarm and change radius while drifting outside

## [1.0.0] - 2026-09-10

### Added
- Initial public Connect IQ Store release (Anchor Point watch app)
- GPS anchor monitoring with adjustable radius and on-watch alarm
- Store listing materials, screenshots, and release package under `release/connectiq/`
