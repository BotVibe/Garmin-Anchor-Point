#!/usr/bin/env python3
"""Static layout budget check for eng/deu/fre on-watch strings.

Estimates pixel width with a conservative monospace-ish budget and fails if
hint/title/menu strings would exceed the usable width on round 260px (fenix7)
or round 454px (venu3) displays. Not a substitute for simulator screenshots,
but catches obviously-too-long translations before sideload.
"""
from __future__ import annotations

import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LOCALES = {
    "eng": ROOT / "resources/strings/strings.xml",
    "deu": ROOT / "resources-deu/strings/strings.xml",
    "fre": ROOT / "resources-fre/strings/strings.xml",
}

# Approx average glyph widths (px) for Garmin FONT_XTINY / FONT_TINY / FONT_SMALL
# on round CIQ devices — conservative (slightly wide) so we fail early.
PX = {"xtiny": 7.0, "tiny": 8.5, "small": 10.0, "medium": 12.0}

# Usable centered text width ≈ diameter * 0.72 (bezel + padding).
DEVICES = {
    "fenix7": 260 * 0.72,
    "venu3": 454 * 0.72,
}

# On-watch centered strings (circular clip). Menu2 / Connect settings use
# rectangular lists and are checked against a wider budget below.
WATCH_BUDGET = {
    "TitleSetup": "small",
    "TitleMonitor": "tiny",
    "TitleAlarm": "medium",
    "AlarmBody": "tiny",
    "HintSetAnchor": "xtiny",
    "HintChangeRadius": "xtiny",
    "HintKeepOpen": "xtiny",
    "HintMonitorMenu": "xtiny",
    "HintAlarmAck": "xtiny",
    "HintAlarmRadius": "xtiny",
    "HintAlarmMenu": "xtiny",
    "HintAlarmMuted": "xtiny",
    "GlanceDetail": "xtiny",
    "AppName": "tiny",
    "StatusOk": "medium",
    "StatusWarn": "medium",
}

# Menu2 rows and Connect IQ settings labels — not circular-clipped.
LIST_BUDGET = {
    "MenuEnd": "tiny",
    "MenuCancel": "tiny",
    "MenuStopTitle": "tiny",
    "MenuRadius": "tiny",
    "SettingRadiusTitle": "tiny",
    "SettingAlarmModeTitle": "tiny",
    "AlarmModeBoth": "tiny",
    "AlarmModeTone": "tiny",
    "AlarmModeVibrate": "tiny",
}
LIST_WIDTH = {"fenix7": 220.0, "venu3": 360.0}


def load_strings(path: Path) -> dict[str, str]:
    tree = ET.parse(path)
    out: dict[str, str] = {}
    for el in tree.getroot().iter("string"):
        sid = el.get("id")
        if not sid:
            continue
        text = "".join(el.itertext())
        text = text.replace("&amp;", "&").replace("&lt;", "<").replace("&gt;", ">")
        out[sid] = text
    return out


def est_width(text: str, font: str) -> float:
    # Wide glyphs (m, w, …) and CJK aside; Latin umlauts ≈ base width.
    return len(text) * PX[font]


def main() -> int:
    fail = 0

    def check(loc: str, strings: dict[str, str], budget_map: dict[str, str], widths: dict[str, float], kind: str) -> None:
        nonlocal fail
        for sid, font in sorted(budget_map.items()):
            if sid not in strings:
                print(f"  FAIL missing {sid}")
                fail += 1
                continue
            text = strings[sid]
            if not text.strip():
                print(f"  FAIL empty {sid}")
                fail += 1
                continue
            w = est_width(text, font)
            for device, budget in widths.items():
                if w > budget:
                    print(
                        f"  FAIL {kind} {device}: {sid}={text!r} ~{w:.0f}px > {budget:.0f}px ({font})"
                    )
                    fail += 1
                else:
                    print(f"  OK   {kind} {device}: {sid} ~{w:.0f}px / {budget:.0f}px")

    for loc, path in LOCALES.items():
        strings = load_strings(path)
        print(f"== {loc} ({path.relative_to(ROOT)}) ==")
        check(loc, strings, WATCH_BUDGET, DEVICES, "watch")
        check(loc, strings, LIST_BUDGET, LIST_WIDTH, "list")
    if fail:
        print(f"Layout budget check failed ({fail} issue(s)).", file=sys.stderr)
        return 1
    print("OK: watch/settings string layout budgets pass for eng/deu/fre.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
