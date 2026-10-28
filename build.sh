#!/bin/zsh
# Builds Taskerz.app in this folder. Usage: ./build.sh [--open]
set -euo pipefail
cd "$(dirname "$0")"

APP="Taskerz.app"

echo "→ Compiling (release)…"
swift build -c release

BIN="$(swift build -c release --show-bin-path)/Taskerz"

echo "→ Assembling $APP…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Taskerz"
cp Support/Info.plist "$APP/Contents/Info.plist"

if [[ ! -f Support/AppIcon.icns ]]; then
  echo "→ Rendering app icon…"
  swift Support/make_icon.swift Support/AppIcon.iconset
  iconutil -c icns Support/AppIcon.iconset -o Support/AppIcon.icns
  rm -rf Support/AppIcon.iconset
fi
cp Support/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

echo "→ Signing (ad-hoc)…"
codesign --force --deep --sign - "$APP"

echo "✓ Built $(pwd)/$APP"
[[ "${1:-}" == "--open" ]] && open "$APP"
exit 0
