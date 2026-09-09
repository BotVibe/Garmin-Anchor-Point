#!/usr/bin/env bash
# Build Anchor Point with Run No Evil unit tests and execute them in the simulator.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
DEVICE="${1:-fenix7}"
OUT_DIR="${ROOT}/bin"
OUT_PRG="${OUT_DIR}/AnchorPoint-${DEVICE}-tests.prg"

if [[ -z "${CIQ_SDK_HOME:-}" ]]; then
  if [[ -f "${HOME}/.Garmin/ConnectIQ/current-sdk.cfg" ]]; then
    CIQ_SDK_HOME="$(cat "${HOME}/.Garmin/ConnectIQ/current-sdk.cfg")"
  elif [[ -x "${HOME}/garmin/connectiq-sdk-8.2.3/bin/monkeyc" ]]; then
    CIQ_SDK_HOME="${HOME}/garmin/connectiq-sdk-8.2.3"
  else
    echo "Set CIQ_SDK_HOME to your Connect IQ SDK directory." >&2
    exit 1
  fi
fi

MONKEYC="${CIQ_SDK_HOME}/bin/monkeyc"
MONKEYDO="${CIQ_SDK_HOME}/bin/monkeydo"
CONNECTIQ="${CIQ_SDK_HOME}/bin/connectiq"

KEY="${CIQ_PRIVATE_KEY:-}"
if [[ -z "${KEY}" ]]; then
  if [[ -f "${HOME}/garmin/developer_key_rsa.pem" ]]; then
    KEY="${HOME}/garmin/developer_key_rsa.pem"
  else
    KEY="${HOME}/garmin/developer_key.pem"
  fi
fi

if [[ ! -x "${MONKEYC}" ]]; then
  echo "monkeyc not found at ${MONKEYC}" >&2
  exit 1
fi
if [[ ! -f "${KEY}" ]]; then
  echo "Developer key not found at ${KEY}." >&2
  exit 1
fi

mkdir -p "${OUT_DIR}"
echo "Building unit-test PRG for ${DEVICE}"
"${MONKEYC}" \
  -f "${ROOT}/monkey.jungle" \
  -d "${DEVICE}" \
  -o "${OUT_PRG}" \
  -y "${KEY}" \
  -t \
  -w \
  -l 1

echo "Wrote ${OUT_PRG}"

if [[ "${SKIP_SIMULATOR:-0}" == "1" ]]; then
  echo "SKIP_SIMULATOR=1 — build only, not running monkeydo."
  exit 0
fi

if [[ ! -x "${MONKEYDO}" ]]; then
  echo "monkeydo not found; PRG built but tests were not executed." >&2
  exit 1
fi

# Launch simulator if connectiq exists (may require GUI libs).
if [[ -x "${CONNECTIQ}" ]]; then
  "${CONNECTIQ}" >/dev/null 2>&1 &
  sleep 2
fi

echo "Running Run No Evil tests via monkeydo -t"
"${MONKEYDO}" "${OUT_PRG}" "${DEVICE}" -t
