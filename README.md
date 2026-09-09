# Anchor Point (Garmin Connect IQ)

Watch-only MVP: set an anchor GPS point, monitor distance for a few hours like a sport session, and alarm **on the watch** if the boat drifts beyond a chosen radius.

## Documentation maintenance

`README.md` and `AGENTS.md` must stay in sync with the project. Whenever behavior, naming, controls, build steps, tests, or scope changes, update both files in the same change. Prefer doing this automatically as part of the work — do not leave docs for a later pass.

## Features

- Continuous GPS while the app session is open
- Set anchor at the current position when the fix is usable
- Radius presets: 15 / 25 / 50 / 75 / 100 m (default 50 m, also in Garmin Connect app settings)
- FIT activity recording (`SPORT_BOATING`, name `Anchor Point`) so the session appears in your activity history
- Monitor screen: distance, radius, GPS quality, runtime, inside/outside status
- Alarm: vibration + tone + full-screen alert until acknowledged
- English UI strings
- Run No Evil unit tests for geo, radius presets, and session state

## Important limits

- The app must stay open for the whole watch (2–3 h typical). Closing it stops monitoring.
- On watches with multitasking, leaving the app can pause GPS; keep Anchor Point in the foreground.
- No phone companion and no internet/Wi‑Fi remote alarm in this MVP.
- Battery use is similar to an outdoor GPS activity.

## Controls

| Screen | Action |
|--------|--------|
| Setup | **UP/DOWN** (or swipe): change radius |
| Setup | **START/ENTER**: set anchor and start session (needs usable GPS) |
| Monitor | **UP/DOWN**: change radius live |
| Monitor | **MENU** / **START** / **BACK**: end session (save / discard / cancel) |
| Alarm | **START/ENTER** / tap / **BACK**: acknowledge |

## Project layout

```
manifest.xml             # watch-app, products, Fit + Positioning
monkey.jungle            # includes source + source-test
source/
  AnchorPointApp.mc      # lifecycle + GPS
  AnchorMonitor.mc       # UI / FIT / attention wrapper
  AnchorSession.mc       # pure monitoring state machine
  Geo.mc                 # haversine + radius breach helpers
  RadiusPresets.mc       # 15–100 m presets
  views/                 # Setup, Monitor, Alarm
  delegates/             # input + stop menu
source-test/             # Run No Evil (:test) methods
resources/               # strings, icon, settings
scripts/build.sh         # normal PRG build
scripts/test.sh          # build with -t and run monkeydo -t
AGENTS.md                # guidance for coding agents
```

## Build (VS Code)

1. Install [Connect IQ SDK Manager](https://developer.garmin.com/connect-iq/sdk/), log in, download an SDK and at least one device (e.g. fenix7).
2. Install the **Monkey C** extension in VS Code and open this folder.
3. Generate a developer key (`Monkey C: Generate a Developer Key`) if you do not have one.
4. `Monkey C: Build Project` or run in the simulator (`Monkey C: Run App`).
5. Sideload the `.prg` via Garmin Express / Connect IQ App, or use the simulator GPS simulation to move outside the radius and verify the alarm.

## Build (CLI)

```bash
# After SDK + device packages are installed:
export CIQ_SDK_HOME="$(cat ~/.Garmin/ConnectIQ/current-sdk.cfg)"
export CIQ_PRIVATE_KEY=~/path/to/developer_key.pem
./scripts/build.sh fenix7
```

## Unit tests (Run No Evil)

Garmin’s **Run No Evil** framework (`Toybox.Test`) runs in the Connect IQ simulator. `(:test)` code is compiled only with `-t` / `--unit-test` and is stripped from normal device builds.

Coverage today:

- `GeoTests.mc` — distance, symmetry, fix quality, outside-radius boundary, GPS string ids
- `RadiusPresetsTests.mc` — preset list, snap-to-nearest, wrap-around nudge
- `AnchorSessionTests.mc` — arming rules, breach → alarm, acknowledge/rearm, stop, radius nudge, enlarging radius

```bash
# Build + run tests in the simulator (needs device package + GUI for simulator):
./scripts/test.sh fenix7

# Build test PRG only:
SKIP_SIMULATOR=1 ./scripts/test.sh fenix7
```

In VS Code: **Monkey C: Run Tests** (Test Explorer).

Manual UI checks (alarm screen / vibration) still need the simulator or a real watch.

## Store release (later)

Export an `.iq` package with the Monkey C export command, add store graphics/description, and submit via the Connect IQ developer portal. Not part of this MVP.

## Roadmap (out of scope)

- Android/iOS companion alarm over Bluetooth
- Internet push to a remote phone (via `makeWebRequest` / backend)
- Background monitoring without an open session
