#!/bin/zsh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

echo "Building AthanBar v2…"
swift build -c release

BIN="$(swift build -c release --show-bin-path)/AthanBarV2"
APP="$ROOT/AthanBarV2.app"
CONTENTS="$APP/Contents"
MACOS="$CONTENTS/MacOS"
RES="$CONTENTS/Resources"

rm -rf "$APP"
mkdir -p "$MACOS" "$RES"

cp "$BIN" "$MACOS/AthanBarV2"
chmod +x "$MACOS/AthanBarV2"

BUNDLE_DIR="$(dirname "$BIN")"
BUNDLE="$BUNDLE_DIR/AthanBarV2_AthanBarV2.bundle"
if [[ -d "$BUNDLE" ]]; then
  cp -R "$BUNDLE" "$RES/"
fi

cat > "$CONTENTS/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>Athan 2.1.1</string>
  <key>CFBundleDisplayName</key>
  <string>Athan 2.1.1</string>
  <key>CFBundleIdentifier</key>
  <string>com.athan.menubar.v2</string>
  <key>CFBundleVersion</key>
  <string>2.1.1</string>
  <key>CFBundleShortVersionString</key>
  <string>2.1.1</string>
  <key>CFBundleExecutable</key>
  <string>AthanBarV2</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSLocationUsageDescription</key>
  <string>Athan uses your location only when you tap Find my location, to load prayer times for your city.</string>
  <key>NSLocationWhenInUseUsageDescription</key>
  <string>Athan uses your location only when you tap Find my location, to load prayer times for your city.</string>
  <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
  <string>Athan uses your location only when you tap Find my location, to load prayer times for your city.</string>
  <key>NSLocalNetworkUsageDescription</key>
  <string>Athan v2 finds Google Nest and Chromecast speakers on your Wi-Fi so Adhan can play on them.</string>
  <key>NSBonjourServices</key>
  <array>
    <string>_googlecast._tcp</string>
  </array>
  <key>NSAppTransportSecurity</key>
  <dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
  </dict>
</dict>
</plist>
PLIST

echo "Built: $APP"
echo "Launching Athan v2 (version 1 is unchanged)…"
open "$APP"
