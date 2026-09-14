# AGENTS.md

Guidance for coding agents working in this repository.

## Product

**Anchor Point** is a Garmin Connect IQ `watch-app` (Monkey C). The MVP is watch-only: continuous GPS, settable radius, and on-watch vibration/tone alarm when the boat leaves the circle. There is **no** FIT / activity recording.

- Connect IQ Store: https://apps.garmin.com/en-US/apps/db28a9a5-5c3f-4c0a-a5cd-fae895c40d0d
- GitHub: https://github.com/BotVibe/Garmin-Anchor-Point

## Documentation maintenance (required)

Keep **`README.md` and `AGENTS.md` automatically updated** whenever you change the project.

Update both files in the **same change** when any of the following moves:

- App name, UI copy, or user-facing terminology
- Controls, screens, or alarm behavior
- Build/sideload/simulator/test steps
- Unit test coverage or how tests are run
- Store listing, privacy text, or publish checklist (`store/`)
- Supported devices, permissions, or API assumptions
- Scope boundaries (what is in / out of MVP)

Do not defer doc updates. Prefer English for all names, UI strings, comments aimed at contributors, README, and this file. When store-facing claims change, update `store/listing-en.md` and `store/privacy-en.md` in the same change.

## Code map

| Path | Role |
|------|------|
| `source/AnchorPointApp.mc` | App lifecycle, GPS enable/disable, glance entry |
| `source/AnchorMonitor.mc` | UI, vibration/tone around session |
| `source/DisplayIdleController.mc` | Display full → dim @30s → off @40s; mute/alarm force full |
| `source/AnchorSession.mc` | Pure state machine (setup/monitoring/alarm) — unit-tested |
| `source/Geo.mc` | Haversine distance, GPS quality gate (`QUALITY_GOOD` to start), outside-radius check |
| `source/RadiusPresets.mc` | Radius presets + snap/nudge helpers |
| `source/ViewLayout.mc` | Round-display hint stacking / safe bottom clamp |
| `source/views/*` | Setup, Monitor, Alarm, Glance screens |
| `source/delegates/*` | Input handling and end-session menu |
| `source-test/*` | Run No Evil `(:test)` methods |
| `resources/strings/strings.xml` | English UI strings |
| `resources/settings/*` | Default radius + alarm style settings |
| `manifest.xml` | App id, products, `Positioning` |
| `scripts/build.sh` | Normal PRG build |
| `scripts/test.sh` | Unit-test build (`-t`) + `monkeydo -t` |
| `store/` | Connect IQ Store listing copy, privacy draft, asset/submit checklists |

## Testing

- Framework: Garmin **Run No Evil** (`Toybox.Test`), simulator only.
- `monkey.jungle` includes `source-test`; `(:test)` symbols are omitted from non-`-t` builds.
- Prefer testing pure logic in `Geo`, `RadiusPresets`, and `AnchorSession`. Keep UI/`Attention` side effects in `AnchorMonitor`.
- When changing geofence, radius, or alarm snooze/ack behavior, add/adjust tests in `source-test/` and update this section + README.
- Run: `./scripts/test.sh fenix7` or VS Code **Monkey C: Run Tests**.

## Conventions

- Language: **English** for app name, strings, docs, and commit messages.
- Product name: `Anchor Point`.
- Radius presets: 15–50 m in 5 m steps, plus 75 / 100 m.
- Start monitoring only when GPS quality is `QUALITY_GOOD` (`Geo.isFixGood`); `QUALITY_USABLE` is not enough.
- Alarm style setting (`AlarmMode`): 0 = tone + vibrate (default), 1 = tone only, 2 = vibrate only.
- Acknowledge snoozes re-alarm for 60 s while still outside; mute UI shows yellow muted-speaker + CCW countdown ring; display stays full during mute/alarm.
- Stop menu labels: **Stop surveillance** / **Continue surveillance**.
- Monitoring display idle: full for 30 s, visual dim, then black/off at 40 s; first tap while off only wakes.
- No FIT / activity recording — end session simply stops monitoring.
- App must remain open while monitoring; do not promise background geofencing unless Connect IQ capabilities change and docs are updated.
- On glance-capable devices, provide `getGlanceView()` so the app appears in the glance list as well as the apps list; glance is preview/launch only (no background GPS).
- Phone companion / internet push are out of MVP unless explicitly requested — if added, update README + AGENTS.md immediately.

## Build notes

- Requires Connect IQ SDK and a downloaded device package (SDK Manager login).
- Developer key required to sign `.prg` / `.iq` builds.
- See README for VS Code, CLI build, test, and **Connect IQ Store publish** steps.
- Store upload and review require a human Garmin developer account; agents prepare `store/` materials and docs but cannot complete portal login/export without that environment.
