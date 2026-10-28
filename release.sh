#!/bin/zsh
# Builds distributable DMGs for Taskerz: Universal, Apple Silicon, and Intel.
#
#   ./release.sh                                   # local build (ad-hoc signed)
#   VERSION=1.2.0 BUILD=5 ./release.sh             # set version numbers
#
# For public distribution (no Gatekeeper warnings) also set:
#   DEVELOPER_ID="Developer ID Application: Your Name (TEAMID)"
#   NOTARY_PROFILE="taskerz-notary"   # created once with: xcrun notarytool store-credentials
set -euo pipefail
cd "$(dirname "$0")"

VERSION="${VERSION:-1.0.0}"
BUILD="${BUILD:-1}"
DEVELOPER_ID="${DEVELOPER_ID:-}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"
MIN_MACOS="14.0"
APP_NAME="Taskerz"

if [[ -n "$NOTARY_PROFILE" && -z "$DEVELOPER_ID" ]]; then
  echo "✗ NOTARY_PROFILE needs DEVELOPER_ID (notarization requires a Developer ID signature)." >&2
  exit 1
fi

step() { print -P "%F{blue}→%f $1"; }

rm -rf dist
mkdir -p dist/work

# ── 1. Compile for both architectures ───────────────────────────────────────
for arch in arm64 x86_64; do
  step "Compiling for $arch…"
  swift build -c release --triple "$arch-apple-macosx$MIN_MACOS" 2>&1 | grep -E "error|warning: |Compiling|Build complete" || true
  [[ -f ".build/$arch-apple-macosx/release/$APP_NAME" ]] || { echo "✗ $arch build failed" >&2; exit 1; }
done

step "Creating universal binary…"
lipo -create \
  ".build/arm64-apple-macosx/release/$APP_NAME" \
  ".build/x86_64-apple-macosx/release/$APP_NAME" \
  -output "dist/work/$APP_NAME-universal"
lipo -info "dist/work/$APP_NAME-universal"

# ── 2. Shared assets ────────────────────────────────────────────────────────
if [[ ! -f Support/AppIcon.icns ]]; then
  step "Rendering app icon…"
  swift Support/make_icon.swift dist/work/AppIcon.iconset
  iconutil -c icns dist/work/AppIcon.iconset -o Support/AppIcon.icns
fi
step "Rendering DMG background…"
mkdir -p dist/work/bg
swift Support/make_dmg_background.swift dist/work/bg >/dev/null
tiffutil -cathidpicheck dist/work/bg/background.png dist/work/bg/background@2x.png -out dist/work/bg/background.tiff >/dev/null 2>&1

# ── 3. App bundles ──────────────────────────────────────────────────────────
sign_app() {
  local app="$1"
  if [[ -n "$DEVELOPER_ID" ]]; then
    codesign --force --timestamp --options runtime \
      --entitlements Support/Taskerz.entitlements --sign "$DEVELOPER_ID" "$app"
  else
    codesign --force --options runtime \
      --entitlements Support/Taskerz.entitlements --sign - "$app"
  fi
  codesign --verify --strict --deep "$app"
}

make_app() {
  local variant="$1" binary="$2"
  local app="dist/work/$variant/$APP_NAME.app"
  mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
  cp "$binary" "$app/Contents/MacOS/$APP_NAME"
  cp Support/Info.plist "$app/Contents/Info.plist"
  cp Support/AppIcon.icns "$app/Contents/Resources/AppIcon.icns"
  /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$app/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD" "$app/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c "Set :LSMinimumSystemVersion $MIN_MACOS" "$app/Contents/Info.plist"
  sign_app "$app"
}

step "Assembling app bundles…"
make_app universal "dist/work/$APP_NAME-universal"
make_app apple-silicon ".build/arm64-apple-macosx/release/$APP_NAME"
make_app intel ".build/x86_64-apple-macosx/release/$APP_NAME"

# ── 4. DMGs ─────────────────────────────────────────────────────────────────
style_dmg() {
  # Lays out the Finder window. Needs Finder automation; skipped quietly if unavailable.
  local volname="$1"
  perl -e 'alarm 45; exec @ARGV' osascript <<EOF >/dev/null 2>&1 || echo "  (Finder styling skipped — DMG still works)"
tell application "Finder"
  tell disk "$volname"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {200, 120, 860, 520}
    set opts to the icon view options of container window
    set arrangement of opts to not arranged
    set icon size of opts to 112
    set text size of opts to 13
    set background picture of opts to file ".background:background.tiff"
    set position of item "$APP_NAME.app" of container window to {170, 190}
    set position of item "Applications" of container window to {490, 190}
    update without registering applications
    delay 1
    close
  end tell
end tell
EOF
}

make_dmg() {
  local variant="$1" label="$2"
  local dmg="dist/$APP_NAME-$VERSION-$label.dmg"
  local staging="dist/work/dmg-$variant"
  local volname="$APP_NAME $VERSION"

  step "Packaging $(basename "$dmg")…"
  mkdir -p "$staging/.background"
  cp -R "dist/work/$variant/$APP_NAME.app" "$staging/"
  ln -s /Applications "$staging/Applications"
  cp dist/work/bg/background.tiff "$staging/.background/background.tiff"

  hdiutil create -quiet -volname "$volname" -srcfolder "$staging" -fs HFS+ -format UDRW -ov "dist/work/$variant-rw.dmg"
  local device
  device=$(hdiutil attach -readwrite -noverify -noautoopen "dist/work/$variant-rw.dmg" | awk '/Apple_HFS/ {print $1}')
  style_dmg "$volname"
  sync
  hdiutil detach -quiet "$device" || hdiutil detach -quiet -force "$device"
  hdiutil convert -quiet "dist/work/$variant-rw.dmg" -format UDZO -imagekey zlib-level=9 -o "$dmg"

  if [[ -n "$DEVELOPER_ID" ]]; then
    codesign --force --timestamp --sign "$DEVELOPER_ID" "$dmg"
  fi
  if [[ -n "$NOTARY_PROFILE" ]]; then
    step "Notarizing $(basename "$dmg") (this can take a few minutes)…"
    xcrun notarytool submit "$dmg" --keychain-profile "$NOTARY_PROFILE" --wait
    xcrun stapler staple "$dmg"
  fi
}

make_dmg universal Universal
make_dmg apple-silicon AppleSilicon
make_dmg intel Intel

# ── 5. Checksums & cleanup ──────────────────────────────────────────────────
(cd dist && shasum -a 256 *.dmg > SHA256SUMS.txt)
rm -rf dist/work

echo
print -P "%F{green}✓ Release $VERSION ($BUILD) ready in $(pwd)/dist%f"
ls -lh dist | awk 'NR>1 {printf "   %-40s %s\n", $9, $5}'
if [[ -z "$DEVELOPER_ID" ]]; then
  echo
  echo "⚠ Ad-hoc signed: users will see “Apple could not verify Taskerz”."
  echo "  Set DEVELOPER_ID and NOTARY_PROFILE for warning-free public distribution."
fi
