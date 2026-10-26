#!/usr/bin/env bash
# Build the UI-smoke harness PRG (includes (:smoke) seed APIs; not for store).
# Output: bin/AnchorPoint-<device>-smoke.prg — never used for store export.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEVICE="${1:-fenix7}"
OUT_DIR="${ROOT}/bin"
OUT_PRG="${OUT_DIR}/AnchorPoint-${DEVICE}-smoke.prg"

if [[ -z "${CIQ_SDK_HOME:-}" ]]; then
  if [[ -f "${HOME}/.Garmin/ConnectIQ/current-sdk.cfg" ]]; then
    CIQ_SDK_HOME="$(cat "${HOME}/.Garmin/ConnectIQ/current-sdk.cfg")"
  else
    echo "Set CIQ_SDK_HOME" >&2
    exit 1
  fi
fi

KEY="${CIQ_PRIVATE_KEY:-}"
if [[ -z "${KEY}" ]]; then
  if [[ -f "${HOME}/garmin/developer_key.der" ]]; then
    KEY="${HOME}/garmin/developer_key.der"
  elif [[ -f "${HOME}/garmin/developer_key_rsa.pem" ]]; then
    KEY="${HOME}/garmin/developer_key_rsa.pem"
  else
    KEY="${HOME}/garmin/developer_key.pem"
  fi
fi

mkdir -p "${OUT_DIR}"
echo "Building UI-smoke PRG for ${DEVICE}"
# Do not pass -x smoke — seed helpers must remain. Do not pass -t (unit tests unused).
"${CIQ_SDK_HOME}/bin/monkeyc" \
  -f "${ROOT}/smoke.jungle" \
  -d "${DEVICE}" \
  -o "${OUT_PRG}" \
  -y "${KEY}" \
  -w \
  -l 1

echo "Wrote ${OUT_PRG}"
