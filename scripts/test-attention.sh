#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
export PATH="/opt/swift/usr/bin:${PATH}"
cd "$root/GlassStatsCore"
exec swift test
