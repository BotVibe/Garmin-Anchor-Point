# AGENTS.md

Guidance for coding agents working in this repository.

## Product

**Anchor Alarm** is a Garmin Connect IQ `watch-app` (Monkey C). The MVP is watch-only: continuous GPS, settable radius, FIT session styled like boating, and on-watch vibration/tone alarm when the boat leaves the circle.

## Documentation maintenance (required)

Keep **`README.md` and `AGENTS.md` automatically updated** whenever you change the project.

Update both files in the **same change** when any of the following moves:

- App name, UI copy, or user-facing terminology
- Controls, screens, or alarm behavior
- Build/sideload/simulator steps
- Supported devices, permissions, or API assumptions
- Scope boundaries (what is in / out of MVP)

Do not defer doc updates. Prefer English for all names, UI strings, comments aimed at contributors, README, and this file.

## Code map

| Path | Role |
|------|------|
| `source/AnchorAlarmApp.mc` | App lifecycle, GPS enable/disable |
| `source/AnchorMonitor.mc` | Anchor, radius, distance, FIT session, alarm state |
| `source/Geo.mc` | Haversine distance and GPS quality helpers |
| `source/views/*` | Setup, Monitor, Alarm screens |
| `source/delegates/*` | Input handling and end-session menu |
| `resources/strings/strings.xml` | English UI strings |
| `resources/settings/*` | Default radius property + Connect settings |
| `manifest.xml` | App id, products, `Fit` + `Positioning` |
| `scripts/build.sh` | CLI build helper |

## Conventions

- Language: **English** for app name, strings, docs, and commit messages.
- Session recording name: `Anchor Alarm` (`Activity.SPORT_BOATING`).
- Radius presets: 15 / 25 / 50 / 75 / 100 m.
- App must remain open while monitoring; do not promise background geofencing unless Connect IQ capabilities change and docs are updated.
- Phone companion / internet push are out of MVP unless explicitly requested — if added, update README + AGENTS.md immediately.

## Build notes

- Requires Connect IQ SDK and a downloaded device package (SDK Manager login).
- Developer key required to sign `.prg` builds.
- See README for VS Code and CLI steps.
