#!/usr/bin/env bash
# Runs the GdUnit4 suites headless. Usage: tools/test.sh [test-dir ...]  (default: test)
# Godot binary: $GODOT_BIN, falling back to the macOS app bundle.
set -u
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
cd "$(dirname "$0")/.."
targets=("$@")
[ ${#targets[@]} -eq 0 ] && targets=(test)
args=()
for t in "${targets[@]}"; do args+=(-a "$t"); done
"$GODOT_BIN" --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode "${args[@]}"
