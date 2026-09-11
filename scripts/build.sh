#!/usr/bin/env bash
# Build Anchor Point for a target device (requires Connect IQ SDK + device package).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEVICE="${1:-fenix7}"
OUT_DIR="${ROOT}/bin"
OUT_PRG="${OUT_DIR}/AnchorPoint-${DEVICE}.prg"

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
  echo "Developer key not found at ${KEY}. Generate one with openssl or the VS Code Monkey C extension." >&2
  exit 1
fi

mkdir -p "${OUT_DIR}"
echo "Building for ${DEVICE} using SDK at ${CIQ_SDK_HOME}"
"${MONKEYC}" \
  -f "${ROOT}/monkey.jungle" \
  -d "${DEVICE}" \
  -o "${OUT_PRG}" \
  -y "${KEY}" \
  -w \
  -l 1

echo "Wrote ${OUT_PRG}"
