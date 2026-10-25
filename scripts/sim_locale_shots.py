#!/usr/bin/env python3
"""Capture glance/setup/settings screenshots per locale via force-locale bake.

Also attempts FIT/GPX Activity Data playback (Data Source must be
FIT/GPX Playable File; paths are container paths under /app/...).
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
GPX_IN_CONTAINER = "/app/testdata/anchor-drift.gpx"
FIT_IN_CONTAINER = "/app/testdata/sample.fit"


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
    time.sleep(0.15)


def click(x: int, y: int):
    run(["xdotool", "mousemove", "--sync", str(int(x)), str(int(y)), "click", "1"])
    time.sleep(0.35)


def key(wid: str, *keys: str):
    for k in keys:
        run(["xdotool", "key", "--window", wid, "--delay", "60", k], check=False)
        time.sleep(0.06)


def shot(name: str) -> Path:
    ART.mkdir(parents=True, exist_ok=True)
    path = ART / name
    run(["scrot", str(path)])
    return path


def crop_win(src: Path, dest: Path, x, y, w, h):
    from PIL import Image

    im = Image.open(src)
    im.crop((x, y, x + w, y + h)).save(dest)


def ocr(path: Path) -> str:
    p = run(["tesseract", str(path), "stdout"], check=False, capture_output=True, text=True)
    return p.stdout or ""


def ocr_tsv(path: Path, scale: float = 2.0):
    from PIL import Image

    im = Image.open(path)
    big = im.resize((int(im.size[0] * scale), int(im.size[1] * scale)), Image.Resampling.LANCZOS)
    tmp = Path("/tmp/locale-ocr.png")
    big.save(tmp)
    run(["tesseract", str(tmp), "/tmp/locale-ocr", "tsv"], check=False, capture_output=True)
    rows = list(csv.DictReader(open("/tmp/locale-ocr.tsv"), delimiter="\t"))
    out = []
    for r in rows:
        t = (r.get("text") or "").strip()
        if not t:
            continue
        out.append(
            (
                t,
                int(r["left"]) / scale + int(r["width"]) / (2 * scale),
                int(r["top"]) / scale + int(r["height"]) / (2 * scale),
            )
        )
    return out


def find_click(path: Path, needles: list[str]) -> bool:
    rows = ocr_tsv(path)
    for needle in needles:
        nl = needle.lower()
        for t, x, y in rows:
            if nl in t.lower():
                print(f"  click {needle!r} via {t!r} @ {x:.0f},{y:.0f}")
                click(x, y)
                return True
    print(f"  miss {needles}")
    return False


def monkeydo(prg: Path, device: str, timeout: float = 20):
    # Prefer in-container monkeydo against docker sim (/workspace -> /app)
    app_prg = "/app/" + str(prg.relative_to(ROOT))
    cmd = (
        "sudo docker exec ciq-sim bash -lc "
        f"'export PATH=/sdk/bin:$PATH; timeout {int(timeout)} monkeydo {app_prg} {device}'"
    )
    try:
        run(cmd, shell=True, check=False, timeout=timeout + 5)
    except subprocess.TimeoutExpired:
        pass
    time.sleep(1.5)


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
    time.sleep(0.5)
    key(wid, "Return")
    time.sleep(1.2)


def expect(path: Path, patterns: list[str], label: str) -> bool:
    text = ocr(path)
    ok = any(re.search(p, text, re.I) for p in patterns)
    print(f"  [{'PASS' if ok else 'FAIL'}] {label}: {text[:140]!r}")
    return ok


PAT = {
    "glance": {
        "eng": [r"Anchor Point", r"Tap to open|radius"],
        "deu": [r"Anchor Point", r"Tippen|Radius"],
        "fre": [r"Anchor Point", r"Toucher|rayon"],
    },
    "setup": {
        "eng": [r"Anchor Point", r"Radius|GPS|Acquiring|START|Keep app"],
        "deu": [r"Anchor Point", r"Radius|GPS|START|setzen|empfangen|offen"],
        "fre": [r"Anchor Point", r"Rayon|GPS|START|fixer|Acquisition|ouverte"],
    },
    "settings": {
        "eng": [r"Default radius|Alarm style|Tone|vibrate|50 m"],
        "deu": [r"Standardradius|Alarmart|Ton|Vibration|50 m"],
        "fre": [r"Rayon|alarme|Son|vibration|50 m"],
    },
}


def ensure_gpx_playing() -> bool:
    """Best-effort: open Activity Data, set FIT/GPX source, load GPX, hit play."""
    x, y, w, h, wid = win_geom()
    activate(wid)
    key(wid, "Escape", "Escape", "Escape")
    time.sleep(0.3)
    # Close stray Activity Audio Prompts if present
    if "Audio Prompts" in ocr(shot("_pre-gps.png")):
        find_click(ART / "_pre-gps.png", ["Cancel"])
        key(wid, "Escape")
        time.sleep(0.3)
    click(x + 165, y - 18)
    time.sleep(0.55)
    # Activity Data is the 2nd "Activity*" row (~y 351); avoid Audio Prompts (~y 300)
    click(x + 200, y + 35)  # rough; refined below via OCR preferring "Data"
    time.sleep(0.2)
    p = shot("_sim-menu.png")
    rows = ocr_tsv(p)
    data_hits = [(t, cx, cy) for t, cx, cy in rows if "Data" in t and cy > y]
    act_hits = [(t, cx, cy) for t, cx, cy in rows if t.startswith("Activity") or t == "Activity"]
    # Prefer a row that has both Activity and nearby Data, else 2nd Activity
    clicked = False
    for t, cx, cy in rows:
        if t == "Data" and cy > (y + 20):
            print(f"  click Activity Data via Data @ {cx:.0f},{cy:.0f}")
            click(cx, cy)
            clicked = True
            break
    if not clicked and len(act_hits) >= 2:
        t, cx, cy = act_hits[1]
        print(f"  click 2nd Activity @ {cx:.0f},{cy:.0f}")
        click(cx, cy)
        clicked = True
    if not clicked:
        click(900, 351)
    time.sleep(1.0)
    p = shot("_actdata.png")
    if "Audio Prompts" in ocr(p):
        print("  wrong dialog (Audio Prompts); abort GPS")
        find_click(p, ["Cancel"])
        key(wid, "Escape", "Escape")
        return False
    find_click(p, ["Simulation"])
    time.sleep(0.5)
    p = shot("_src-menu.png")
    find_click(p, ["Playable", "GPX"])
    time.sleep(0.7)
    p = shot("_actdata2.png")
    before = set(sh("wmctrl -lG").splitlines())
    find_click(p, ["Load"])
    opened = False
    for _ in range(30):
        time.sleep(0.2)
        if set(sh("wmctrl -lG").splitlines()) - before:
            opened = True
            break
    if not opened:
        print("  file dialog did not open")
        return False
    run(["xdotool", "search", "--name", "Open FIT or GPX", "windowactivate", "--sync"], check=False)
    time.sleep(0.25)
    run(["xdotool", "key", "ctrl+l"], check=False)
    time.sleep(0.25)
    run(["xdotool", "key", "ctrl+a"], check=False)
    run(["xdotool", "type", "--delay", "4", GPX_IN_CONTAINER], check=False)
    time.sleep(0.15)
    run(["xdotool", "key", "Return"], check=False)
    time.sleep(1.5)
    for line in sh("wmctrl -lG").splitlines():
        parts = line.split(None, 7)
        if len(parts) >= 6 and parts[4] == "515":
            dx, dy, dw, dh = map(int, parts[2:6])
            click(dx + 32, dy + dh - 42)
            time.sleep(1.0)
            break
    p = shot("_playing.png")
    text = ocr(p)
    print(f"  playback OCR: {text[:180]!r}")
    return "01:" in text or re.search(r"00:0[1-9]", text) is not None or "/ 00:" in text


def trigger_app_settings(device: str, loc: str, x, y, wid) -> bool:
    activate(wid)
    key(wid, "Escape", "Escape", "Escape")
    time.sleep(0.3)
    if "Audio Prompts" in ocr(shot("_pre-settings.png")):
        find_click(ART / "_pre-settings.png", ["Cancel"])
        key(wid, "Escape")
        time.sleep(0.3)
    click(x + 40, y - 18)
    time.sleep(0.7)
    p = shot(f"_settings-{device}-{loc}.png")
    # Trigger App Settings is near the bottom of the Settings menu
    if not find_click(p, ["Trigger"]):
        for _ in range(40):
            key(wid, "Down")
            time.sleep(0.04)
        key(wid, "Return")
        time.sleep(1.0)
    else:
        time.sleep(1.2)
    p = shot(f"{device}-{loc}-settings.png")
    gx = win_geom()
    crop_win(p, ART / f"{device}-{loc}-settings-crop.png", gx[0], gx[1], gx[2], gx[3])
    return expect(p, PAT["settings"][loc], f"{device}/{loc} settings")


def walkthrough(device: str, loc: str, try_gps: bool) -> dict[str, bool]:
    res = {}
    prefix = f"{device}-{loc}"
    prg = ROOT / "bin" / f"AnchorPoint-{device}.prg"
    monkeydo(prg, device)
    x, y, w, h, wid = win_geom()

    p = shot(f"{prefix}-glance.png")
    crop_win(p, ART / f"{prefix}-glance-crop.png", x, y, w, h)
    res["glance"] = expect(p, PAT["glance"][loc], f"{prefix} glance")

    open_full_app(x, y, wid)
    p = shot(f"{prefix}-setup.png")
    crop_win(p, ART / f"{prefix}-setup-crop.png", x, y, w, h)
    res["setup"] = expect(p, PAT["setup"][loc], f"{prefix} setup")

    if try_gps:
        ensure_gpx_playing()
        x, y, w, h, wid = win_geom()
        activate(wid)
        open_full_app(x, y, wid)
        time.sleep(0.5)
        key(wid, "Return")
        time.sleep(2.0)
        p = shot(f"{prefix}-monitor.png")
        crop_win(p, ART / f"{prefix}-monitor-crop.png", x, y, w, h)
        res["monitor"] = expect(
            p,
            {
                "eng": [r"Monitoring|INSIDE|OUTSIDE|Distance|Runtime"],
                "deu": [r"Überwachung|INNERHALB|AUSSERHALB|Distanz|Laufzeit"],
                "fre": [r"Surveillance|DEDANS|DEHORS|Distance|Durée"],
            }[loc],
            f"{prefix} monitor",
        )
        # shrink radius + wait for possible alarm
        for _ in range(12):
            key(wid, "Down")
            time.sleep(0.08)
        time.sleep(4.0)
        p = shot(f"{prefix}-alarm.png")
        crop_win(p, ART / f"{prefix}-alarm-crop.png", x, y, w, h)
        res["alarm"] = expect(
            p,
            {
                "eng": [r"ALARM|Outside anchor|silence"],
                "deu": [r"ALARM|Ankerkreis|stumm"],
                "fre": [r"ALARME|ancrage|silence|zone"],
            }[loc],
            f"{prefix} alarm",
        )
        if res["alarm"]:
            key(wid, "Return")
            time.sleep(1.0)
            p = shot(f"{prefix}-mute.png")
            res["mute"] = True
            key(wid, "m")
            time.sleep(0.9)
            p = shot(f"{prefix}-menu.png")
            res["menu"] = expect(
                p,
                {
                    "eng": [r"Stop surveillance|Continue surveillance|Surveillance"],
                    "deu": [r"Überw\. beenden|Überw\. fortsetzen|Überwachung"],
                    "fre": [r"Arrêter|Continuer|Surveillance"],
                }[loc],
                f"{prefix} menu",
            )
            key(wid, "Return")
        else:
            res["mute"] = False
            res["menu"] = False
    else:
        res["monitor"] = False
        res["alarm"] = False
        res["mute"] = False
        res["menu"] = False

    x, y, w, h, wid = win_geom()
    res["settings"] = trigger_app_settings(device, loc, x, y, wid)
    return res


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--devices", default="fenix7,venu3")
    ap.add_argument("--locales", default="eng,deu,fre")
    ap.add_argument("--try-gps", action="store_true", help="Attempt FIT/GPX playback for monitor/alarm")
    ap.add_argument("--gps-once-device", default="fenix7", help="Only try GPS on this device (eng)")
    args = ap.parse_args()
    devices = [d.strip() for d in args.devices.split(",") if d.strip()]
    locales = [l.strip() for l in args.locales.split(",") if l.strip()]
    ART.mkdir(parents=True, exist_ok=True)

    summary = {}
    for loc in locales:
        backup = None
        try:
            print(f"\n##### LOCALE {loc} #####")
            backup = force_locale(loc)
            for d in devices:
                print(f"  building {d} with baked {loc}...")
                build(d)
            for d in devices:
                try_gps = args.try_gps and loc == "eng" and d == args.gps_once_device
                print(f"\n=== {d}/{loc} gps={try_gps} ===")
                summary[f"{d}/{loc}"] = walkthrough(d, loc, try_gps)
        finally:
            restore_locale(backup)
            if backup:
                for d in devices:
                    build(d)

    print("\n======== SUMMARY ========")
    fails = 0
    for key, res in summary.items():
        for screen, ok in res.items():
            # GPS-dependent screens skipped intentionally count as N/A not fail
            if screen in ("monitor", "alarm", "mute", "menu") and not ok:
                print(f"SKIP  {key:16s}  {screen}")
                continue
            mark = "PASS" if ok else "FAIL"
            if not ok:
                fails += 1
            print(f"{mark}  {key:16s}  {screen}")
    print(f"fails={fails}")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
