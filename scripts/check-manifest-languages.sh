#!/usr/bin/env bash
# Fail if a resources-*<lang> folder exists whose language is not declared in
# manifest.xml (<iq:language>) or not registered in monkey.jungle (base.lang.*).
# Without the manifest entry, monkeyc silently drops those strings
# ("String resources will be ignored").
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="${ROOT}/manifest.xml"
JUNGLE="${ROOT}/monkey.jungle"

declared="$(grep -oE '<iq:language>[a-z]{3}</iq:language>' "${MANIFEST}" \
  | sed -E 's#<iq:language>([a-z]{3})</iq:language>#\1#' | sort -u)"

if ! grep -qx 'eng' <<<"${declared}"; then
  echo "FAIL: manifest.xml does not declare the default language 'eng'." >&2
  exit 1
fi

fail=0
found=""
shopt -s nullglob
for dir in "${ROOT}"/resources-*/; do
  name="$(basename "${dir}")"
  # Language is the last dash-separated qualifier, e.g. resources-deu or resources-fenix7-deu.
  lang="${name##*-}"
  [[ "${lang}" =~ ^[a-z]{3}$ ]] || continue
  [[ -d "${dir}strings" ]] || continue
  found+="${lang}"$'\n'
  if ! grep -qx "${lang}" <<<"${declared}"; then
    echo "FAIL: ${name} has string resources but '${lang}' is missing from manifest.xml <iq:languages>." >&2
    fail=1
  fi
  if [[ "${name}" == "resources-${lang}" ]] && ! grep -qE "^[[:space:]]*base\.lang\.${lang}[[:space:]]*=" "${JUNGLE}"; then
    echo "FAIL: ${name} is not registered in monkey.jungle (base.lang.${lang})." >&2
    fail=1
  fi
done

if [[ "${fail}" -ne 0 ]]; then
  echo "Manifest language check failed." >&2
  exit 1
fi

langs="$(printf '%s' "${found}" | sort -u | tr '\n' ' ')"
echo "OK: manifest declares $(tr '\n' ' ' <<<"${declared}")— covers resource languages: ${langs:-none}"
