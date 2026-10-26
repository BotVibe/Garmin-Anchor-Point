#!/usr/bin/env python3
"""Deterministic UI-state screenshots via the smoke harness PRG.

Smoke PRG omits getGlanceView so monkeydo opens the seeded full-app view
directly (no glance double-click). Glance screenshots use the release PRG.
Each capture uses a fresh simulator container.
"""
from __future__ import annotations

import os
import re
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
INI = Path.home() / ".Garmin/ConnectIQ/simulator.ini"
PHASE_FILE = ROOT / "source-smoke" / "SmokePhase.mc"
DISPLAY = os.environ.get("DISPLAY", ":1")
ENV = {**os.environ, "DISPLAY": DISPLAY, "PATH": f"{SDK}/bin:{os.environ.get('PATH', '')}"}

LANG_CODE = {"eng": 0, "deu": 7, "fre": 6}

SCREENS = [
    "setup",
    "monitor-inside",
    "monitor-outside",
    "alarm",
    "mute",
    "menu",
]
SCREEN_PHASE = {name: i for i, name in enumerate(SCREENS)}

EXPECT = {
    "glance": {
        # venu3 glance OCR often drops the title; detail line is enough.
        "eng": [[r"Tap to open"], [r"Anchor Point", r"Tap|radius"]],
        "deu": [[r"Tipp"], [r"Anchor Point", r"Tipp|50\s*m"]],
        "fre": [[r"Toucher"], [r"Anchor Point", r"Toucher|rayon"]],
    },
    "setup": {
        "eng": [[r"Keep app open"]],
        "deu": [[r"offen lassen|App offen"]],
        "fre": [[r"garder|ouverte"]],
    },
    "monitor-inside": {
        # Prefer status word; fall back to seeded distance (colored OCR is flaky).
        "eng": [[r"INSIDE"], [r"Distance:\s*11\s*m", r"Monitoring|GPS good"]],
        "deu": [[r"INNERHALB"], [r"(Distanz|Distance):\s*11"]],
        "fre": [[r"DEDANS"], [r"Distance:\s*11\s*m"]],
    },
    "monitor-outside": {
        "eng": [[r"OUTSIDE"], [r"Distance:\s*189\s*m", r"Monitoring"]],
        "deu": [[r"AUSSERHALB|AUßERHALB|AUSSER"], [r"(Distanz|Distance):\s*189"]],
        "fre": [[r"DEHORS"], [r"Distance:\s*189\s*m"]],
    },
    "alarm": {
        "eng": [[r"\bALARM\b"], [r"Outside anchor|silence 60"]],
        "deu": [[r"\bALARM\b"], [r"Ankerkreis|60s stumm"]],
        "fre": [[r"ALARME"], [r"cercle|60\s*s"]],
    },
    "mute": {
        "eng": [[r"Alarm paused|paused\s*\d"], [r"Distance:\s*189\s*m", r"paused|OUTSIDE"]],
        "deu": [[r"pausiert"], [r"(Distanz|Distance):\s*189", r"pausiert|AUSSER"]],
        "fre": [[r"Alarme en pause|en pause"], [r"Distance:\s*189", r"pause|DEHORS"]],
    },
    "menu": {
        "eng": [[r"Stop surveillance"]],
        "deu": [[r"beenden|Überwachung|Uberwachung|Uberw"]],
        "fre": [[r"Arrêter|Arreter|surveillance|Continuer"]],
    },
}


def run(cmd, check=False, timeout=None, **kw):
    return subprocess.run(cmd, check=check, timeout=timeout, env=ENV, **kw)


def sh(cmd: str) -> str:
    p = run(cmd, shell=True, text=True, capture_output=True)
    return (p.stdout or "") + (p.stderr or "")


def win_geom():
    out = sh("xdotool search --name 'CIQ Simulator'")
    wids = [l.strip() for l in out.splitlines() if l.strip().isdigit()]
    if not wids:
        raise RuntimeError("CIQ Simulator not found")
    wid = wids[-1]
    g = sh(f"xdotool getwindowgeometry --shell {wid}")
    vals = dict(line.split("=", 1) for line in g.splitlines() if "=" in line)
    return int(vals["X"]), int(vals["Y"]), int(vals["WIDTH"]), int(vals["HEIGHT"]), wid


def shot(name: str) -> Path:
    """Capture desktop to ART/name. Unlink first — scrot never overwrites."""
    ART.mkdir(parents=True, exist_ok=True)
    path = ART / name
    stem = path.stem
    for attempt in range(4):
        if path.exists():
            path.unlink()
        for stale in ART.glob(f"{stem}_*.png"):
            try:
                stale.unlink()
            except OSError:
                pass
        run(["scrot", str(path)], check=False)
        if path.exists() and path.stat().st_size > 1000:
            return path
        # scrot sometimes writes stem_NNN.png instead; adopt newest sidecar.
        sides = sorted(ART.glob(f"{stem}_*.png"), key=lambda p: p.stat().st_mtime, reverse=True)
        if sides:
            sides[0].replace(path)
            if path.exists() and path.stat().st_size > 1000:
                return path
        time.sleep(0.4)
    raise RuntimeError(f"scrot did not write {path}")


def crop_win(src: Path, dest: Path, x, y, w, h):
    from PIL import Image

    Image.open(src).crop((x, y, x + w, y + h)).save(dest)


def ocr_preprocess(path: Path) -> Path:
    """Grayscale tuned for CIQ UI: white/green/yellow on black or red.

    Max-RGB washes yellow into red backgrounds; use max(G,B) plus luminance
    so status / mute countdown text stays readable for tesseract.
    Intermediate files go under /tmp (not the artifact dir).
    """
    from PIL import Image
    import numpy as np

    im = Image.open(path).convert("RGB")
    arr = np.asarray(im, dtype=np.uint16)
    r, g, b = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2]
    # Yellow/green/cyan/white on red or black.
    chroma = np.maximum(g, b)
    white = np.minimum(np.minimum(r, g), b)
    bright = np.maximum(chroma, white).astype(np.uint8)
    out = Image.fromarray(bright, mode="L")
    out = out.point(lambda v: 0 if v < 50 else (255 if v > 160 else int((v - 50) * 255 / 110)))
    prep = Path("/tmp") / f"smoke-ocr-{path.stem}.png"
    out.save(prep)
    return prep


def ocr(path: Path) -> str:
    prep = ocr_preprocess(path)
    texts = []
    for img in (prep, path):
        for psm in ("6", "11"):
            p = run(
                ["tesseract", str(img), "stdout", "--psm", psm],
                capture_output=True,
                text=True,
            )
            texts.append(p.stdout or "")
    return "\n".join(texts)


def matches(text: str, screen: str, loc: str) -> bool:
    for group in EXPECT[screen][loc]:
        if all(re.search(p, text, re.I) for p in group):
            return True
    return False


def set_language(code: int):
    try:
        text = INI.read_text() if INI.exists() else ""
    except PermissionError:
        text = sh(f"sudo cat {INI}")
    if re.search(r"^Language=", text, re.M):
        text = re.sub(r"^Language=.*$", f"Language={code}", text, flags=re.M)
    else:
        text += f"\nLanguage={code}\n"
    tmp = Path("/tmp/simulator.ini.smoke")
    tmp.write_text(text)
    run(["sudo", "cp", str(tmp), str(INI)], check=True)
    run(["sudo", "chmod", "666", str(INI)], check=False)


def write_phase(phase: int):
    PHASE_FILE.write_text(
        "import Toybox.Lang;\n\n"
        "//! Overwritten by scripts/sim_ui_states.py before each single-screen capture.\n"
        "//! 0=setup 1=inside 2=outside 3=alarm 4=mute 5=menu\n"
        "module SmokePhase {\n"
        f"    const PHASE as Number = {phase};\n"
        "}\n"
    )


def dismiss_audio_prompts():
    out = sh("xdotool search --name 'Activity Audio Prompts'")
    for wid in out.split():
        if wid.isdigit():
            run(["xdotool", "windowkill", wid], check=False)


def restart_sim():
    run("sudo docker rm -f ciq-sim >/dev/null 2>&1", shell=True)
    time.sleep(0.5)
    for name in ("CIQ Simulator", "Activity Audio Prompts"):
        for wid in sh(f"xdotool search --name '{name}'").split():
            if wid.isdigit():
                run(["xdotool", "windowkill", wid], check=False)
    run("xhost +local:root >/dev/null 2>&1", shell=True)
    sdk = str(SDK)
    cmd = (
        "sudo docker run -d --name ciq-sim --network host "
        f"-e DISPLAY={DISPLAY} -e QT_X11_NO_MITSHM=1 "
        "-v /tmp/.X11-unix:/tmp/.X11-unix "
        "-v /home/ubuntu/.Xauthority:/root/.Xauthority:ro "
        "-v /workspace:/app "
        "-v /home/ubuntu/garmin/developer_key.der:/key.der:ro "
        "-v /home/ubuntu/.Garmin/ConnectIQ:/root/.Garmin/ConnectIQ "
        f"-v {sdk}:/sdk:ro "
        "-w /app --entrypoint bash "
        "ghcr.io/matco/connectiq-tester:latest "
        "-lc 'export PATH=/sdk/bin:$PATH; /sdk/bin/simulator >/tmp/sim.log 2>&1; sleep infinity'"
    )
    run(cmd, shell=True, check=True)
    time.sleep(8)


def face_crop(win_crop: Path) -> Path:
    """Tighter square around the round face — better OCR, less bezel chrome."""
    from PIL import Image

    im = Image.open(win_crop)
    w, h = im.size
    side = min(w, h) * 55 // 100
    cx, cy = w // 2, h * 48 // 100
    box = (cx - side // 2, cy - side // 2, cx + side // 2, cy + side // 2)
    out = Path("/tmp") / f"smoke-face-{win_crop.stem}.png"
    im.crop(box).save(out)
    return out


def save_crop(prefix: str, screen: str) -> tuple[Path, str]:
    dismiss_audio_prompts()
    x, y, w, h, _ = win_geom()
    # Canonical artifact: device-lang-screen.png (window crop, not full desktop).
    dest = ART / f"{prefix}-{screen}.png"
    if dest.exists():
        dest.unlink()
    full = shot(f"_full-{prefix}-{screen}.png")
    crop_win(full, dest, x, y, w, h)
    try:
        full.unlink()
    except OSError:
        pass
    # OCR the face; artifact is the window crop.
    return dest, ocr(face_crop(dest))


def capture_glance(device: str, loc: str) -> bool:
    """Release PRG shows glance on load (has getGlanceView)."""
    prefix = f"{device}-{loc}"
    release = ROOT / "bin" / f"AnchorPoint-{device}.prg"
    if not release.exists():
        run([str(ROOT / "scripts/build.sh"), device], check=True)
    restart_sim()
    proc = subprocess.Popen(
        "sudo docker exec ciq-sim bash -lc "
        f"'export PATH=/sdk/bin:$PATH; timeout 35 monkeydo /app/bin/AnchorPoint-{device}.prg {device}'",
        shell=True,
        env=ENV,
    )
    try:
        time.sleep(12)
        ok = False
        last = ""
        for _ in range(8):
            _, last = save_crop(prefix, "glance")
            if matches(last, "glance", loc):
                ok = True
                break
            time.sleep(0.6)
        print(f"  [{'PASS' if ok else 'FAIL'}] {prefix} glance: {last[:160]!r}", flush=True)
        return ok
    finally:
        try:
            proc.terminate()
            proc.wait(timeout=3)
        except Exception:
            pass


def capture_one(device: str, loc: str, screen: str) -> bool:
    """Smoke PRG opens seeded view directly (no glance)."""
    prefix = f"{device}-{loc}"
    write_phase(SCREEN_PHASE[screen])
    run([str(ROOT / "scripts/build-smoke.sh"), device], check=True)
    restart_sim()
    proc = subprocess.Popen(
        "sudo docker exec ciq-sim bash -lc "
        f"'export PATH=/sdk/bin:$PATH; timeout 70 monkeydo /app/bin/AnchorPoint-{device}-smoke.prg {device}'",
        shell=True,
        env=ENV,
    )
    try:
        # Direct full-app load; allow a few seconds for first paint / menu push.
        time.sleep(10 if screen != "menu" else 12)
        last = ""
        ok = False
        for attempt in range(10):
            dismiss_audio_prompts()
            _, last = save_crop(prefix, screen)
            if matches(last, screen, loc):
                ok = True
                break
            # Still on splash / blank? wait longer.
            time.sleep(1.0)
        print(f"  [{'PASS' if ok else 'FAIL'}] {prefix} {screen}: {last[:160]!r}", flush=True)
        return ok
    finally:
        try:
            proc.terminate()
            proc.wait(timeout=3)
        except Exception:
            pass


def capture_pair(device: str, loc: str) -> dict[str, bool]:
    set_language(LANG_CODE[loc])
    res = {"glance": capture_glance(device, loc)}
    for screen in SCREENS:
        try:
            res[screen] = capture_one(device, loc, screen)
        except Exception as e:
            print(f"  [FAIL] {device}-{loc} {screen}: ERROR {e}", flush=True)
            res[screen] = False
    write_phase(0)
    return res


def main() -> int:
    devices = [d.strip() for d in os.environ.get("SMOKE_DEVICES", "fenix7,venu3").split(",") if d.strip()]
    locales = [l.strip() for l in os.environ.get("SMOKE_LOCALES", "eng,deu,fre").split(",") if l.strip()]
    ART.mkdir(parents=True, exist_ok=True)

    for d in devices:
        run([str(ROOT / "scripts/build.sh"), d], check=True)

    summary = {}
    for loc in locales:
        for d in devices:
            print(f"\n===== {d} / {loc} =====", flush=True)
            try:
                summary[f"{d}/{loc}"] = capture_pair(d, loc)
            except Exception as e:
                print(f"  ERROR: {e}", flush=True)
                summary[f"{d}/{loc}"] = {s: False for s in ["glance"] + SCREENS}

    write_phase(0)

    print("\n======== SUMMARY ========", flush=True)
    fails = 0
    for key, res in summary.items():
        for screen, ok in res.items():
            mark = "PASS" if ok else "FAIL"
            if not ok:
                fails += 1
            print(f"{mark}  {key:14s}  {screen}", flush=True)
    print(f"fails={fails}", flush=True)
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
