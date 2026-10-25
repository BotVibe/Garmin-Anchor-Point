#!/usr/bin/env python3
"""Deterministic UI-state screenshots via the smoke harness PRG.

For each device × language: restart sim with simulator.ini Language=,
load AnchorPoint-<device>-smoke.prg, screenshot setup then advance with
Enter through monitor-inside, monitor-outside, alarm, mute, menu.

Glance is captured from the release PRG (same Language=).
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
DISPLAY = os.environ.get("DISPLAY", ":1")
ENV = {**os.environ, "DISPLAY": DISPLAY, "PATH": f"{SDK}/bin:{os.environ.get('PATH', '')}"}

# Empirically: Language=0 eng, 6 fre, 7 deu on CIQ simulator 9.2
LANG_CODE = {"eng": 0, "deu": 7, "fre": 6}

SCREENS = [
    "setup",
    "monitor-inside",
    "monitor-outside",
    "alarm",
    "mute",
    "menu",
]

EXPECT = {
    "glance": {
        "eng": [r"Anchor Point", r"Tap to open|radius"],
        "deu": [r"Anchor Point", r"Tippen|Radius"],
        "fre": [r"Anchor Point", r"Toucher|rayon"],
    },
    "setup": {
        "eng": [r"Anchor Point", r"Radius|GPS|START|Keep app"],
        "deu": [r"Anchor Point", r"Radius|GPS|setzen|offen|empfangen"],
        "fre": [r"Anchor Point", r"Rayon|GPS|fixer|ouverte|Acquisition"],
    },
    "monitor-inside": {
        "eng": [r"Monitoring|INSIDE|Distance"],
        "deu": [r"Überwachung|INNERHALB|Distanz"],
        "fre": [r"Surveillance|DEDANS|Distance"],
    },
    "monitor-outside": {
        "eng": [r"OUTSIDE|Distance|Monitoring"],
        "deu": [r"AUSSERHALB|Distanz|Überwachung"],
        "fre": [r"DEHORS|Distance|Surveillance"],
    },
    "alarm": {
        "eng": [r"ALARM|Outside anchor|silence"],
        "deu": [r"ALARM|Ankerkreis|stumm"],
        "fre": [r"ALARME|ancrage|silence|zone"],
    },
    "mute": {
        "eng": [r"paused|OUTSIDE|INSIDE"],
        "deu": [r"pausiert|AUSSERHALB|INNERHALB"],
        "fre": [r"pause|DEHORS|DEDANS"],
    },
    "menu": {
        "eng": [r"Stop surveillance|Continue|Surveillance"],
        "deu": [r"Überw\.|Überwachung"],
        "fre": [r"Arrêter|Continuer|Surveillance"],
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
    ART.mkdir(parents=True, exist_ok=True)
    path = ART / name
    run(["scrot", str(path)])
    return path


def crop_win(src: Path, dest: Path, x, y, w, h):
    from PIL import Image

    Image.open(src).crop((x, y, x + w, y + h)).save(dest)


def ocr(path: Path) -> str:
    p = run(["tesseract", str(path), "stdout"], capture_output=True, text=True)
    return p.stdout or ""


def expect(path: Path, screen: str, loc: str, label: str) -> bool:
    text = ocr(path)
    pats = EXPECT[screen][loc]
    ok = any(re.search(p, text, re.I) for p in pats)
    print(f"  [{'PASS' if ok else 'FAIL'}] {label}: {text[:140]!r}")
    return ok


def set_language(code: int):
    # simulator.ini is often root-owned when the Docker sim writes it.
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


def restart_sim():
    run("sudo docker rm -f ciq-sim >/dev/null 2>&1", shell=True)
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
    time.sleep(7)


def monkeydo(prg_host: Path, device: str, timeout: float = 22):
    app_prg = "/app/" + str(prg_host.relative_to(ROOT))
    cmd = (
        "sudo docker exec ciq-sim bash -lc "
        f"'export PATH=/sdk/bin:$PATH; timeout {int(timeout)} monkeydo {app_prg} {device}'"
    )
    try:
        run(cmd, shell=True, timeout=timeout + 5)
    except subprocess.TimeoutExpired:
        pass
    time.sleep(1.8)


def focus_sim():
    run("wmctrl -a 'CIQ Simulator'", shell=True, check=False)
    time.sleep(0.2)


def press_enter(wid: str):
    focus_sim()
    run(["xdotool", "windowactivate", "--sync", wid], check=False)
    time.sleep(0.15)
    run(["xdotool", "key", "--window", wid, "Return"], check=False)
    time.sleep(1.5)


def open_full_app(x: int, y: int, wid: str):
    """Leave glance and enter the full-app initial view."""
    run(["xdotool", "windowactivate", "--sync", wid], check=False)
    time.sleep(0.15)
    # Glance row / watch face — same offset that works for fenix7 release opens.
    run(["xdotool", "mousemove", "--sync", str(x + 150), str(y + 197), "click", "1"], check=False)
    time.sleep(0.45)
    run(["xdotool", "key", "--window", wid, "Return"], check=False)
    time.sleep(1.5)


def on_setup(path: Path, loc: str) -> bool:
    text = ocr(path)
    return any(re.search(p, text, re.I) for p in EXPECT["setup"][loc])


def capture_pair(device: str, loc: str) -> dict[str, bool]:
    res = {}
    prefix = f"{device}-{loc}"
    set_language(LANG_CODE[loc])
    restart_sim()

    # Glance from release PRG
    release = ROOT / "bin" / f"AnchorPoint-{device}.prg"
    if not release.exists():
        run([str(ROOT / "scripts/build.sh"), device], check=True)
    monkeydo(release, device)
    x, y, w, h, wid = win_geom()
    p = shot(f"{prefix}-glance.png")
    crop_win(p, ART / f"{prefix}-glance-crop.png", x, y, w, h)
    res["glance"] = expect(p, "glance", loc, f"{prefix} glance")

    # Smoke harness for the rest
    smoke = ROOT / "bin" / f"AnchorPoint-{device}-smoke.prg"
    if not smoke.exists():
        run([str(ROOT / "scripts/build-smoke.sh"), device], check=True)
    monkeydo(smoke, device)
    x, y, w, h, wid = win_geom()
    time.sleep(0.4)

    # Smoke often lands on glance first — open full app to reach seeded setup.
    p_probe = shot(f"_probe-{prefix}.png")
    if not on_setup(p_probe, loc):
        open_full_app(x, y, wid)
        x, y, w, h, wid = win_geom()
        # Retry once if still glance
        p_probe = shot(f"_probe2-{prefix}.png")
        if not on_setup(p_probe, loc):
            open_full_app(x, y, wid)
            x, y, w, h, wid = win_geom()
            time.sleep(0.5)

    for i, screen in enumerate(SCREENS):
        if i > 0:
            # Focus watch face then Enter so SmokeNavDelegate receives the key.
            run(["xdotool", "mousemove", "--sync", str(x + w // 2), str(y + h // 2), "click", "1"], check=False)
            time.sleep(0.25)
            press_enter(wid)
            x, y, w, h, wid = win_geom()
        p = shot(f"{prefix}-{screen}.png")
        crop_win(p, ART / f"{prefix}-{screen}-crop.png", x, y, w, h)
        res[screen] = expect(p, screen, loc, f"{prefix} {screen}")

    return res


def main() -> int:
    devices = [d.strip() for d in os.environ.get("SMOKE_DEVICES", "fenix7,venu3").split(",") if d.strip()]
    locales = [l.strip() for l in os.environ.get("SMOKE_LOCALES", "eng,deu,fre").split(",") if l.strip()]
    ART.mkdir(parents=True, exist_ok=True)

    # Ensure smoke + release PRGs exist
    for d in devices:
        run([str(ROOT / "scripts/build-smoke.sh"), d], check=True)
        run([str(ROOT / "scripts/build.sh"), d], check=True)

    summary = {}
    for loc in locales:
        for d in devices:
            print(f"\n===== {d} / {loc} =====")
            try:
                summary[f"{d}/{loc}"] = capture_pair(d, loc)
            except Exception as e:
                print(f"  ERROR: {e}")
                summary[f"{d}/{loc}"] = {s: False for s in ["glance"] + SCREENS}

    print("\n======== SUMMARY ========")
    fails = 0
    for key, res in summary.items():
        for screen, ok in res.items():
            mark = "PASS" if ok else "FAIL"
            if not ok:
                fails += 1
            print(f"{mark}  {key:14s}  {screen}")
    print(f"fails={fails}")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
