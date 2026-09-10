# Anchor Point (Garmin Connect IQ)

Watch-only MVP: set an anchor GPS point, monitor distance for a few hours like a sport session, and alarm **on the watch** if the boat drifts beyond a chosen radius.

## Documentation maintenance

`README.md` and `AGENTS.md` must stay in sync with the project. Whenever behavior, naming, controls, build steps, tests, store listing, or scope changes, update both files (and `store/` listing docs when relevant) in the same change. Prefer doing this automatically as part of the work — do not leave docs for a later pass.

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
store/                   # Connect IQ Store listing, privacy, checklists
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

## Publish to the Connect IQ Store

Prepared materials live in [`store/`](store/) (listing copy, privacy draft, asset checklist). Agents and contributors must keep **README.md**, **AGENTS.md**, and `store/` listing docs updated together when publishing steps or product claims change.

### Already prepared in this repo

- English store listing text: [`store/listing-en.md`](store/listing-en.md)
- Privacy draft (on-device GPS/FIT): [`store/privacy-en.md`](store/privacy-en.md)
- Screenshot checklist: [`store/assets/README.md`](store/assets/README.md)
- Pre-submit checklist: [`store/submission-checklist.md`](store/submission-checklist.md)
- App icon source: `resources/drawables/launcher_icon.svg`
- Device list / permissions: `manifest.xml`

### Remaining steps (manual — need your Garmin account & local SDK)

1. **Developer account**  
   Create/sign in at the [Garmin Connect IQ developer site](https://developer.garmin.com/connect-iq/submit-an-app/) and accept the developer agreement.

2. **Replace placeholders**  
   Put a real support/privacy email into `store/listing-en.md` and `store/privacy-en.md` (or host the privacy text on your site and link it).

3. **Final testing**  
   Run unit tests, then manually verify setup → monitoring → alarm → save/discard in the simulator and ideally on one real watch. Complete [`store/submission-checklist.md`](store/submission-checklist.md).

4. **Capture screenshots**  
   Follow [`store/assets/README.md`](store/assets/README.md) and save images under `store/assets/` (or upload directly from disk).

5. **Export `.iq`**  
   In VS Code: Command Palette → **Monkey C: Export Project** → choose an output folder.  
   This builds a signed `.iq` for all products in `manifest.xml` (needs SDK + device packages + developer key).

6. **Upload & listing**  
   Open [Submit an App](https://developer.garmin.com/connect-iq/submit-an-app/), upload the `.iq`, paste listing text from `store/listing-en.md`, add screenshots, set Free / no companion app / English.

7. **Submit for review**  
   Garmin typically reviews within about **72 hours**. While pending, the app is not public; you can often preview/install it yourself. Fix any rejection notes and resubmit.

Official docs: [Publishing to the Store](https://developer.garmin.com/connect-iq/core-topics/publishing-to-the-store/), [App Review Guidelines](https://developer.garmin.com/connect-iq/app-review-guidelines/).

### Review notes specific to Anchor Point

- Describe the app honestly: **not** a life-saving navigation system; GPS accuracy varies; **app must stay open**.
- Permissions used: Positioning + Fit only (no Communications / no developer cloud in MVP).
- Safety-oriented wording in the prepared listing is intentional — keep those caveats if you edit the text.

## Roadmap (out of scope)

- Android/iOS companion alarm over Bluetooth
- Internet push to a remote phone (via `makeWebRequest` / backend)
- Background monitoring without an open session
