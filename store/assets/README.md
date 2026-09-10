# Store assets

PNG/JPG files here are copied into `release/connectiq/store/` on every release build (`scripts/sync-store-graphics.sh`).

## Included

| File | Purpose |
|------|---------|
| `launcher-icon-60.png` / `120` / `512` | Exported from `resources/drawables/launcher_icon.svg` |
| `screenshot-setup.png` | Setup screen (radius + GPS) |
| `screenshot-monitoring.png` | Monitoring INSIDE |
| `screenshot-alarm.png` | Alarm screen |
| `screenshot-menu.png` | End-session menu |
| `promo-banner.png` | Optional 16:9 listing banner |

Screenshots are listing mockups matching in-app strings. Prefer re-capturing from the Connect IQ Simulator on a real device target before final store submission if the portal rejects mockups.

## Regenerate icons only

```bash
./scripts/sync-store-graphics.sh
```
