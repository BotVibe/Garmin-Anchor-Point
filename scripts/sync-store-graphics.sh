#!/usr/bin/env bash
# Sync store graphics into release/connectiq/store and refresh launcher PNG exports.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ASSETS="$ROOT/store/assets"
SVG="$ROOT/resources/drawables/launcher_icon.svg"
REL="$ROOT/release/connectiq/store"
mkdir -p "$ASSETS" "$REL"
if command -v rsvg-convert >/dev/null 2>&1 && [[ -f "$SVG" ]]; then
  rsvg-convert -w 60 -h 60 "$SVG" -o "$ASSETS/launcher-icon-60.png"
  rsvg-convert -w 120 -h 120 "$SVG" -o "$ASSETS/launcher-icon-120.png"
  rsvg-convert -w 512 -h 512 "$SVG" -o "$ASSETS/launcher-icon-512.png"
fi
find "$REL" -mindepth 1 -delete 2>/dev/null || true
shopt -s nullglob
pngs=("$ASSETS"/*.png "$ASSETS"/*.jpg "$ASSETS"/*.jpeg "$ASSETS"/*.webp)
for f in "${pngs[@]}"; do
  [[ -f "$f" ]] || continue
  cp -a "$f" "$REL/"
done
count=$(find "$REL" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) | wc -l | tr -d ' ')
echo "Synced $count store graphic(s) -> $REL"
