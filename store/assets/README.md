# Store assets checklist

Place final PNG/JPG files in this folder before upload (do not commit large binaries unless needed).

## Launcher icon (in app)

Already in the project: `resources/drawables/launcher_icon.svg`  
Export Project will package the app icon. Optionally refine the SVG before release.

## Screenshots (you capture)

Capture from the Connect IQ **Simulator** or a real watch. Typical useful set:

1. **Setup** — GPS status + radius (e.g. 50 m)
2. **Monitoring inside** — INSIDE + distance
3. **Alarm** — ALARM screen after leaving the circle
4. Optional: end-session menu (Save / Discard)

### Tips

- Use a round device target that matches many watches (e.g. fenix7) for primary shots.
- Simulate GPS movement in the simulator to show inside → outside → alarm.
- Avoid claiming Garmin partnership; do not use Garmin logos you do not have rights to.
- Keep text readable; crop to the watch face if the portal expects square/round crops.

Exact portal dimensions can change; follow the upload form’s size hints when submitting.

## Suggested filenames

```
assets/screenshot-setup.png
assets/screenshot-monitoring.png
assets/screenshot-alarm.png
assets/screenshot-menu.png
```

## Promo graphic (optional)

Some listing UIs accept an additional banner. If offered, use a simple 16:9 image with the name **Anchor Point** and a short tagline (no Garmin trademarks).
