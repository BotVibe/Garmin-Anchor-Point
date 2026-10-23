#!/usr/bin/env bash
# Verify default / German / French string resource IDs match (bidirectional).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEFAULT="${ROOT}/resources/strings/strings.xml"
DEU="${ROOT}/resources-deu/strings/strings.xml"
FRE="${ROOT}/resources-fre/strings/strings.xml"

extract_ids() {
  local file="$1"
  if [[ ! -f "${file}" ]]; then
    echo "Missing string resource file: ${file}" >&2
    exit 1
  fi
  # Match <string id="Foo">…</string> (and self-closing forms if ever used).
  grep -oE '<string[[:space:]]+id="[^"]+"' "${file}" \
    | sed -E 's/.*id="([^"]+)"/\1/' \
    | sort -u
}

ids_default="$(extract_ids "${DEFAULT}")"
ids_deu="$(extract_ids "${DEU}")"
ids_fre="$(extract_ids "${FRE}")"

fail=0

compare() {
  local label="$1"
  local left_label="$2"
  local right_label="$3"
  local left_ids="$4"
  local right_ids="$5"
  local missing
  missing="$(comm -23 <(printf '%s\n' "${left_ids}") <(printf '%s\n' "${right_ids}") || true)"
  if [[ -n "${missing}" ]]; then
    echo "FAIL ${label}: IDs in ${left_label} missing from ${right_label}:" >&2
    printf '  %s\n' ${missing} >&2
    fail=1
  fi
}

compare "default→deu" "resources" "resources-deu" "${ids_default}" "${ids_deu}"
compare "deu→default" "resources-deu" "resources" "${ids_deu}" "${ids_default}"
compare "default→fre" "resources" "resources-fre" "${ids_default}" "${ids_fre}"
compare "fre→default" "resources-fre" "resources" "${ids_fre}" "${ids_default}"
compare "deu→fre" "resources-deu" "resources-fre" "${ids_deu}" "${ids_fre}"
compare "fre→deu" "resources-fre" "resources-deu" "${ids_fre}" "${ids_deu}"

if [[ "${fail}" -ne 0 ]]; then
  echo "String resource parity check failed." >&2
  exit 1
fi

count="$(printf '%s\n' "${ids_default}" | grep -c . || true)"
echo "OK: ${count} string IDs match across resources, resources-deu, and resources-fre."
