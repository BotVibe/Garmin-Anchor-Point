#!/usr/bin/env bash
# Build the release jungle for every product in manifest.xml and assert the
# smoke harness is not linked (no SmokeNav / seedSetup symbols in the PRG).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -z "${CIQ_SDK_HOME:-}" ]]; then
  CIQ_SDK_HOME="$(cat "${HOME}/.Garmin/ConnectIQ/current-sdk.cfg")"
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
OUT="${ROOT}/bin/release-check"
mkdir -p "${OUT}"

mapfile -t PRODUCTS < <(grep -oP 'iq:product id="\K[^"]+' "${ROOT}/manifest.xml")
echo "Building release PRG for ${#PRODUCTS[@]} products…"

FAIL=0
for product in "${PRODUCTS[@]}"; do
  prg="${OUT}/AnchorPoint-${product}.prg"
  echo "--- ${product} ---"
  # jungle excludeAnnotations strips (:smoke); do not pass -x (incompatible with -f).
  if ! "${CIQ_SDK_HOME}/bin/monkeyc" \
      -f "${ROOT}/monkey.jungle" \
      -d "${product}" \
      -o "${prg}" \
      -y "${KEY}" \
      -r \
      -w \
      -l 1 >/tmp/release-build-${product}.log 2>&1; then
    echo "FAIL build ${product}"
    tail -20 "/tmp/release-build-${product}.log" || true
    FAIL=$((FAIL + 1))
    continue
  fi
  if strings "${prg}" | grep -qE 'SmokeNavDelegate|SmokeAnchorPointApp|seedSetupGoodGps|seedMonitoringInside|smokePrepare'; then
    echo "FAIL smoke symbols present in ${product}"
    FAIL=$((FAIL + 1))
  else
    echo "OK ${product}"
  fi
done

if [[ "${FAIL}" -ne 0 ]]; then
  echo "Release verify failed (${FAIL})." >&2
  exit 1
fi
echo "OK: all ${#PRODUCTS[@]} release products build without smoke harness."
