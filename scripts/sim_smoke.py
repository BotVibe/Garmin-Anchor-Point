#!/usr/bin/env python3
"""Anchor Point Connect IQ simulator smoke driver (Linux/X11).

Uses frame-relative menu clicks (Settings lives above the client area) and
OCR (tesseract TSV) to click Language / Set GPS Quality entries. For DE/FR
layouts, --force-locale-build copies locale strings into default resources/
so the simulator renders that language without depending on SetLanguage.
"""
from __future__ import annotations

import argparse
import csv
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ART = Path(os.environ.get("SMOKE_ARTIFACT_DIR", "/opt/cursor/artifacts/screenshots/smoke-2.2.1"))
SDK = Path(
    os.environ.get("CIQ_SDK_HOME")
    or Path.home().joinpath(".Garmin/ConnectIQ/current-sdk.cfg").read_text().strip()
)
KEY = Path(os.environ.get("CIQ_PRIVATE_KEY", Path.home() / "garmin/developer_key.der"))
DISPLAY = os.environ.get("DISPLAY", ":1")
ENV = {**os.environ, "DISPLAY": DISPLAY, "PATH": f"{SDK}/bin:{os.environ.get('PATH', '')}"}


def run(cmd, check=True, timeout=None, **kw):
    return subprocess.run(cmd, check=check, timeout=timeout, env=ENV, **kw)


def sh(cmd: str) -> str:
    p = run(cmd, shell=True, text=True, capture_output=True, check=False)
    return (p.stdout or "") + (p.stderr or "")


def win_geom():
    out = sh("xdotool search --name 'CIQ Simulator'")
    wids = [l.strip() for l in out.splitlines() if l.strip().isdigit()]
    if not wids:
        raise RuntimeError("CIQ Simulator window not found")
    wid = wids[-1]
    g = sh(f"xdotool getwindowgeometry --shell {wid}")
    vals = dict(line.split("=", 1) for line in g.splitlines() if "=" in line)
    return int(vals["X"]), int(vals["Y"]), int(vals["WIDTH"]), int(vals["HEIGHT"]), wid


def activate(wid: str):
    run(["xdotool", "windowactivate", "--sync", wid], check=False)
    run(["xdotool", "windowfocus", "--sync", wid], check=False)
    time.sleep(0.12)


def click(x: int, y: int):
    run(["xdotool", "mousemove", "--sync", str(int(x)), str(int(y)), "click", "1"])
    time.sleep(0.3)


def key(wid: str, *keys: str, delay: int = 70):
    for k in keys:
        run(["xdotool", "key", "--window", wid, "--delay", str(delay), k], check=False)
        time.sleep(0.07)


def shot(name: str) -> Path:
    ART.mkdir(parents=True, exist_ok=True)
    path = ART / name
    run(["scrot", str(path)])
    return path


def ocr_text(path: Path) -> str:
    p = run(["tesseract", str(path), "stdout"], check=False, capture_output=True, text=True)
    return p.stdout or ""


def ocr_tsv(path: Path):
    out_base = Path("/tmp/smoke-ocr")
    run(["tesseract", str(path), str(out_base), "tsv"], check=False, capture_output=True)
    tsv = Path(str(out_base) + ".tsv")
    if not tsv.exists():
        return []
    with tsv.open() as f:
        return list(csv.DictReader(f, delimiter="\t"))


def find_text_click(path: Path, needle: str, scale: float = 1.0):
    """Return absolute click coords for first TSV token matching needle (case-insensitive)."""
    rows = ocr_tsv(path)
    needle_l = needle.lower()
    for r in rows:
        t = (r.get("text") or "").strip()
        if not t:
            continue
        if needle_l in t.lower() or t.lower() in needle_l:
            left = int(r["left"]) / scale
            top = int(r["top"]) / scale
            w = int(r["width"]) / scale
            h = int(r["height"]) / scale
            return left + w / 2, top + h / 2, t
    return None


def open_settings(x, y, wid):
    activate(wid)
    key(wid, "Escape", "Escape")
    time.sleep(0.25)
    click(x + 40, y - 18)
    time.sleep(0.6)


def click_settings_item(substr: str) -> bool:
    """Open Settings, screenshot, OCR-click an item containing substr."""
    x, y, w, h, wid = win_geom()
    open_settings(x, y, wid)
    path = shot(f"_settings-{substr.replace(' ', '_')}.png")
    # Upscale for OCR
    from PIL import Image

    im = Image.open(path)
    # Focus left half where dropdown appears
    crop = im.crop((max(0, x - 20), max(0, y - 30), x + 360, y + h))
    big = crop.resize((crop.size[0] * 2, crop.size[1] * 2), Image.Resampling.LANCZOS)
    tmp = Path("/tmp/settings-crop.png")
    big.save(tmp)
    hit = find_text_click(tmp, substr, scale=2.0)
    if not hit:
        # try full screenshot
        hit = find_text_click(path, substr, scale=1.0)
        if not hit:
            print(f"  OCR miss for settings item {substr!r}")
            key(wid, "Escape", "Escape")
            return False
        cx, cy, tok = hit
    else:
        cx, cy, tok = hit
        # convert crop-local to absolute: crop origin (x-20, y-30)
        cx += max(0, x - 20)
        cy += max(0, y - 30)
    print(f"  click settings '{tok}' at ({cx:.0f},{cy:.0f})")
    click(cx, cy)
    time.sleep(0.5)
    return True


def set_language(label: str) -> bool:
    """label: English / German / French"""
    if not click_settings_item("Language"):
        return False
    time.sleep(0.4)
    # Submenu should be open to the right — screenshot and click language
    path = shot(f"_lang-sub-{label}.png")
    hit = find_text_click(path, label, scale=1.0)
    if not hit:
        # try first letters via keyboard
        x, y, w, h, wid = win_geom()
        for ch in label:
            key(wid, ch)
            time.sleep(0.04)
        key(wid, "Return")
        time.sleep(0.3)
        key(wid, "Escape", "Escape")
        print(f"  language {label}: keyboard fallback")
        return True
    cx, cy, tok = hit
    print(f"  language click '{tok}' at ({cx:.0f},{cy:.0f})")
    click(cx, cy)
    time.sleep(0.4)
    x, y, w, h, wid = win_geom()
    key(wid, "Escape", "Escape")
    return True


def set_gps_good() -> bool:
    if not click_settings_item("GPS"):
        # try full phrase via scrolling
        x, y, w, h, wid = win_geom()
        open_settings(x, y, wid)
        for _ in range(30):
            key(wid, "Down")
            time.sleep(0.05)
        key(wid, "Right")
        time.sleep(0.4)
    else:
        # After clicking Set GPS Quality row, open submenu
        x, y, w, h, wid = win_geom()
        key(wid, "Right")
        time.sleep(0.5)
    path = shot("_gps-quality-sub.png")
    hit = find_text_click(path, "Good")
    if hit:
        cx, cy, tok = hit
        click(cx, cy)
        print(f"  GPS quality '{tok}'")
    else:
        x, y, w, h, wid = win_geom()
        for ch in "Good":
            key(wid, ch)
            time.sleep(0.04)
        key(wid, "Return")
    time.sleep(0.3)
    x, y, w, h, wid = win_geom()
    key(wid, "Escape", "Escape")
    return True


def start_activity_data() -> None:
    """Simulation → Activity Data (best-effort)."""
    x, y, w, h, wid = win_geom()
    activate(wid)
    key(wid, "Escape", "Escape")
    time.sleep(0.2)
    click(x + 165, y - 18)  # Simulation
    time.sleep(0.5)
    path = shot("_simulation-menu.png")
    hit = find_text_click(path, "Activity")
    if hit:
        cx, cy, tok = hit
        click(cx, cy)
        print(f"  simulation '{tok}'")
        time.sleep(0.8)
        # Try to hit a play control if a window opened — press space/return
        key(wid, "Return")
        time.sleep(0.5)
    else:
        key(wid, "Escape")
    key(wid, "Escape")


def monkeydo(prg: Path, device: str, timeout: float = 18):
    try:
        run([str(SDK / "bin/monkeydo"), str(prg), device], timeout=timeout, check=False)
    except subprocess.TimeoutExpired:
        pass
    time.sleep(1.2)


def build(device: str) -> Path:
    out = ROOT / "bin" / f"AnchorPoint-{device}.prg"
    run(
        [
            str(SDK / "bin/monkeyc"),
            "-f",
            str(ROOT / "monkey.jungle"),
            "-d",
            device,
            "-o",
            str(out),
            "-y",
            str(KEY),
            "-w",
            "-l",
            "1",
        ]
    )
    return out


def force_locale(locale: str) -> Path | None:
    default = ROOT / "resources/strings/strings.xml"
    if locale == "eng":
        return None
    src = ROOT / f"resources-{locale}/strings/strings.xml"
    backup = ROOT / "resources/strings/strings.xml.smoke-bak"
    shutil.copy2(default, backup)
    shutil.copy2(src, default)
    return backup


def restore_locale(backup: Path | None):
    if backup and backup.exists():
        shutil.move(str(backup), str(ROOT / "resources/strings/strings.xml"))


def open_full_app(x, y, wid):
    activate(wid)
    click(x + 150, y + 197)
    time.sleep(0.8)
    key(wid, "Return")
    time.sleep(1.0)


def expect(path: Path, patterns: list[str], label: str) -> bool:
    text = ocr_text(path)
    ok = any(re.search(p, text, re.I) for p in patterns)
    print(f"  [{'PASS' if ok else 'FAIL'}] {label}: {patterns} :: {text[:160]!r}")
    return ok


PAT = {
    "glance": {
        "eng": [r"Anchor Point", r"Tap to open|radius"],
        "deu": [r"Anchor Point", r"Tippen|Radius"],
        "fre": [r"Anchor Point", r"Toucher|rayon"],
    },
    "setup": {
        "eng": [r"Anchor Point", r"Radius|GPS|Acquiring|START"],
        "deu": [r"Anchor Point", r"Radius|GPS|START|setzen|empfangen"],
        "fre": [r"Anchor Point", r"Rayon|GPS|START|fixer|Acquisition"],
    },
    "monitor": {
        "eng": [r"Monitoring|INSIDE|OUTSIDE|Distance|Runtime"],
        "deu": [r"Überwachung|INNERHALB|AUSSERHALB|Distanz|Laufzeit"],
        "fre": [r"Surveillance|DEDANS|DEHORS|Distance|Durée"],
    },
    "alarm": {
        "eng": [r"ALARM|Outside anchor|silence"],
        "deu": [r"ALARM|Ankerkreis|stumm"],
        "fre": [r"ALARME|ancrage|silence|zone"],
    },
    "mute": {
        "eng": [r"paused|OUTSIDE|INSIDE|Alarm"],
        "deu": [r"pausiert|AUSSERHALB|INNERHALB"],
        "fre": [r"pause|DEHORS|DEDANS"],
    },
    "menu": {
        "eng": [r"Stop surveillance|Continue surveillance|Surveillance"],
        "deu": [r"Überw\. beenden|Überw\. fortsetzen|Überwachung"],
        "fre": [r"Arrêter|Continuer|Surveillance"],
    },
    "settings": {
        "eng": [r"Default radius|Alarm style|Tone|vibrate|50 m"],
        "deu": [r"Standardradius|Alarmart|Ton|Vibration|50 m"],
        "fre": [r"Rayon|alarme|Son|vibration|50 m"],
    },
}


def walkthrough(device: str, loc: str) -> dict[str, bool]:
    res = {}
    prefix = f"{device}-{loc}"
    prg = ROOT / "bin" / f"AnchorPoint-{device}.prg"
    monkeydo(prg, device)
    x, y, w, h, wid = win_geom()

    p = shot(f"{prefix}-glance.png")
    res["glance"] = expect(p, PAT["glance"][loc], f"{prefix} glance")

    open_full_app(x, y, wid)
    p = shot(f"{prefix}-setup.png")
    res["setup"] = expect(p, PAT["setup"][loc], f"{prefix} setup")

    # GPS + activity data
    set_gps_good()
    start_activity_data()
    x, y, w, h, wid = win_geom()
    activate(wid)
    open_full_app(x, y, wid)  # in case menus stole focus
    time.sleep(0.5)
    key(wid, "Return")  # start monitoring
    time.sleep(2.0)
    p = shot(f"{prefix}-monitor.png")
    res["monitor"] = expect(p, PAT["monitor"][loc], f"{prefix} monitor")

    # Try to breach: shrink radius repeatedly; activity data may move outside
    for _ in range(10):
        key(wid, "Down")
        time.sleep(0.08)
    time.sleep(3.0)
    p = shot(f"{prefix}-alarm.png")
    res["alarm"] = expect(p, PAT["alarm"][loc], f"{prefix} alarm")
    if res["alarm"]:
        key(wid, "Return")
        time.sleep(1.0)
        p = shot(f"{prefix}-mute.png")
        res["mute"] = expect(p, PAT["mute"][loc], f"{prefix} mute")
    else:
        res["mute"] = False
        print(f"  [FAIL] {prefix} mute skipped (no alarm)")

    key(wid, "m")
    time.sleep(0.9)
    p = shot(f"{prefix}-menu.png")
    res["menu"] = expect(p, PAT["menu"][loc], f"{prefix} menu")
    key(wid, "Return")  # stop
    time.sleep(1.0)
    p = shot(f"{prefix}-after-stop.png")
    res["stop"] = expect(p, PAT["setup"][loc], f"{prefix} after-stop")

    # App settings editor
    if click_settings_item("Settings"):
        # might have clicked wrong; try Trigger App Settings
        pass
    x, y, w, h, wid = win_geom()
    open_settings(x, y, wid)
    path = shot(f"_before-trigger-settings.png")
    hit = find_text_click(path, "Trigger")
    if hit:
        click(hit[0], hit[1])
        time.sleep(1.2)
        p = shot(f"{prefix}-settings.png")
        res["settings"] = expect(p, PAT["settings"][loc], f"{prefix} settings")
        key(wid, "Escape", "Escape", "Escape")
    else:
        res["settings"] = False
        print(f"  [FAIL] {prefix} settings editor not opened")
        key(wid, "Escape", "Escape")

    return res


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--devices", default="fenix7,venu3")
    ap.add_argument("--locales", default="eng,deu,fre")
    ap.add_argument(
        "--force-locale-build",
        action="store_true",
        help="Bake locale into default resources/ for reliable DE/FR UI",
    )
    ap.add_argument("--also-set-language", action="store_true", help="Also call Settings→Language")
    args = ap.parse_args()
    devices = [d.strip() for d in args.devices.split(",") if d.strip()]
    locales = [l.strip() for l in args.locales.split(",") if l.strip()]
    ART.mkdir(parents=True, exist_ok=True)

    summary = {}
    for loc in locales:
        backup = None
        try:
            print(f"\n##### LOCALE {loc} #####")
            if args.force_locale_build:
                backup = force_locale(loc)
                for d in devices:
                    print(f"  building {d} with baked {loc}...")
                    build(d)
            if args.also_set_language:
                set_language({"eng": "English", "deu": "German", "fre": "French"}[loc])
            for d in devices:
                if not args.force_locale_build:
                    if not (ROOT / "bin" / f"AnchorPoint-{d}.prg").exists():
                        build(d)
                print(f"\n=== {d}/{loc} ===")
                summary[f"{d}/{loc}"] = walkthrough(d, loc)
        finally:
            restore_locale(backup)
            if backup:
                for d in devices:
                    build(d)

    print("\n======== SUMMARY ========")
    fails = 0
    for key, res in summary.items():
        for screen, ok in res.items():
            mark = "PASS" if ok else "FAIL"
            if not ok:
                fails += 1
            print(f"{mark}  {key:16s}  {screen}")
    print(f"fails={fails}")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
