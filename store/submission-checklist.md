# Pre-submission checklist

## Code / package

- [ ] `manifest.xml` product list matches devices you want in the store
- [ ] App name is **Anchor Point** (`resources/strings/strings.xml`)
- [ ] Version string updated if needed (`AppVersion`)
- [ ] Unit tests pass: `./scripts/test.sh <device>` (or VS Code Run Tests)
- [ ] Manual simulator pass: set anchor → move outside → alarm → acknowledge → save/discard
- [ ] Sideload on at least one real watch if possible
- [ ] Export `.iq` via **Monkey C: Export Project** (release build)

## Listing

- [ ] Paste text from [listing-en.md](listing-en.md)
- [ ] Replace support / privacy emails with real addresses
- [ ] Host or paste [privacy-en.md](privacy-en.md) if the portal asks for a privacy policy URL
- [ ] Upload screenshots from [assets/](assets/)
- [ ] Mark price Free; no companion app; no ANT+

## Safety / accuracy (review risk)

- [ ] Description states this is **not** a life-saving navigation system
- [ ] Description states the app must **stay open** for monitoring
- [ ] No exaggerated “always-on background” claims

## Account

- [ ] Garmin Connect IQ developer account accepted agreement
- [ ] Contact info in developer profile is current
