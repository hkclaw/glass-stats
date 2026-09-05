#!/usr/bin/env bash
# Structural checks that can run on Linux. Does not compile the Mac app.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

fail=0
need() {
  if [[ ! -e "$1" ]]; then
    echo "missing $1"
    fail=1
  fi
}

need GlassStats.xcodeproj/project.pbxproj
need GlassStats.xcodeproj/xcshareddata/xcschemes/GlassStats.xcscheme
need project.yml
need LICENSE
need README.md
need GlassStats/GlassStatsApp.swift
need GlassStats/GlassStats.entitlements
need GlassStats/Sampling/HostCPU.swift
need GlassStats/Sampling/HostMemory.swift
need GlassStats/UI/GlassTheme.swift
need GlassStats/Assets.xcassets/AppIcon.appiconset/icon_1024.png

grep -q 'LSUIElement' GlassStats.xcodeproj/project.pbxproj project.yml || {
  echo "LSUIElement missing from project settings"
  fail=1
}
grep -q 'PBXFileSystemSynchronizedRootGroup' GlassStats.xcodeproj/project.pbxproj || {
  echo "folder-synced group missing"
  fail=1
}
grep -q 'host_processor_info' GlassStats/Sampling/MachSupport.swift || {
  echo "CPU sampler missing host_processor_info"
  fail=1
}
grep -q 'HOST_VM_INFO64' GlassStats/Sampling/MachSupport.swift || {
  echo "memory sampler missing HOST_VM_INFO64"
  fail=1
}
grep -q 'ENABLE_APP_SANDBOX = NO' GlassStats.xcodeproj/project.pbxproj || {
  echo "sandbox must stay off for process listing"
  fail=1
}
if grep -R -n -E 'Double\.random|Int\.random\(in:|arc4random|placeholderPercent|fakeCPU' --include='*.swift' GlassStats; then
  echo "possible fake metrics"
  fail=1
fi
if grep -R -n -E 'SMCKit|exelban/stats|github.com/exelban' --include='*.swift' GlassStats; then
  echo "Stats-derived identifiers found"
  fail=1
fi
grep -q 'Not affiliated' README.md LICENSE GlassStats/UI/Settings/SettingsView.swift || true
grep -q 'Not affiliated' README.md || {
  echo "README missing affiliation disclaimer"
  fail=1
}

if [[ "$fail" -ne 0 ]]; then
  echo "verify-skeleton: FAIL"
  exit 1
fi
echo "verify-skeleton: OK"
