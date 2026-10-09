#!/usr/bin/env bash
# Render README interface previews. These are layout mockups, not a live Mac capture.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
out="$root/docs/images"
mkdir -p "$out"
chrome="${CHROME:-google-chrome}"

shot() {
  local html="$1" png="$2" width="$3" height="$4"
  local profile
  profile="$(mktemp -d)"
  timeout 25 "$chrome" \
    --headless=new \
    --no-sandbox \
    --disable-dev-shm-usage \
    --disable-gpu \
    --hide-scrollbars \
    --no-first-run \
    --disable-extensions \
    --user-data-dir="$profile" \
    --force-device-scale-factor=2 \
    --window-size="${width},${height}" \
    --virtual-time-budget=3000 \
    --timeout=8000 \
    --screenshot="$png" \
    "file://$html"
  rm -rf "$profile"
}

shot "$root/scripts/previews/popover.html" "$out/popover.png" 1100 720
shot "$root/scripts/previews/settings.html" "$out/settings.png" 1100 640
echo "wrote $out/popover.png"
echo "wrote $out/settings.png"
