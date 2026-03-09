#!/bin/bash
# ============================================================
#  MacSweep v3.3 — One-Command Builder
#  Generates Xcode project, compiles the app, creates DMG
#
#  Features:
#   • Auto-detects Apple Silicon (arm64) vs Intel (x86_64)
#   • Professional DMG with gradient background
#   • Code-signed ad-hoc for local use
#
#  Usage:  bash build.sh
# ============================================================

set -e
APP="MacSweep"
VERSION="3.3"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BUILD_DIR="$SCRIPT_DIR/build"
DMG_DIR="$SCRIPT_DIR/dist"

echo ""
echo "  ╔══════════════════════════════════════════╗"
echo "  ║     MacSweep v${VERSION} Builder               ║"
echo "  ║     Free & Open Source Mac Cleaner       ║"
echo "  ╚══════════════════════════════════════════╝"
echo ""

# ── Fix 2: Architecture auto-detection ──────────────────────
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    BUILD_ARCH="arm64"
    echo "  ⚡ Detected: Apple Silicon (arm64)"
elif [ "$ARCH" = "x86_64" ]; then
    BUILD_ARCH="x86_64"
    echo "  🖥  Detected: Intel (x86_64)"
else
    BUILD_ARCH="$(uname -m)"
    echo "  ❓ Unknown arch: $ARCH — building for $BUILD_ARCH"
fi
echo ""

# ── Check requirements ──────────────────────────────────────
echo "  Checking requirements..."

if ! command -v xcodebuild &>/dev/null; then
    echo "  ✗ Xcode not found. Please install Xcode from the App Store."
    exit 1
fi

if ! command -v python3 &>/dev/null; then
    echo "  ✗ Python3 not found."
    exit 1
fi

XCODE_VERSION=$(xcodebuild -version | head -1)
echo "  ✓ $XCODE_VERSION"
echo "  ✓ Python3 found"
echo "  ✓ Architecture: $BUILD_ARCH"
echo ""

# ── Generate Xcode project (or reuse existing) ──────────────
echo "  📦 Preparing Xcode project..."
cd "$SCRIPT_DIR"
if [ -f "$SCRIPT_DIR/generate_project.py" ]; then
    python3 generate_project.py
else
    echo "  ⚠ generate_project.py not found, reusing existing $APP.xcodeproj"
fi

if [ ! -d "$APP.xcodeproj" ]; then
    echo "  ✗ $APP.xcodeproj not found."
    echo "    Restore generate_project.py or add the project file."
    exit 1
fi

# ── Generate App Icon from PNG ─────────────────────────────
PNG_LOGO="$HOME/Desktop/MacSweep/PNG/Main app icon.png"
ICON_DIR="$SCRIPT_DIR/$APP/Assets.xcassets/AppIcon.appiconset"

if [ -f "$PNG_LOGO" ]; then
    echo "  🎨 Generating app icon from PNG logo..."
    
    # Use our Python .icns generator (no iconutil needed)
    ICNS_PATH="$SCRIPT_DIR/$APP/AppIcon.icns"
    python3 "$SCRIPT_DIR/make_icns.py" "$PNG_LOGO" "$ICNS_PATH"
    
    # Also copy into asset catalog for Xcode
    mkdir -p "$ICON_DIR"
    sips -z 1024 1024 "$PNG_LOGO" --out "$ICON_DIR/AppIcon-1024.png" >/dev/null 2>&1
    cat > "$ICON_DIR/Contents.json" << 'ICONJSON'
{
  "images" : [
    {
      "filename" : "AppIcon-1024.png",
      "idiom" : "mac",
      "size" : "512x512",
      "scale" : "2x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
ICONJSON
    echo "  ✓ AppIcon.appiconset updated"
else
    echo "  ⚠ PNG logo not found at: $PNG_LOGO"
    echo "    Please place 'Main app icon.png' in ~/Desktop/MacSweep/PNG/"
fi

# ── Copy brand logo PNGs into Assets.xcassets ──────────────
ASSETS_DIR="$SCRIPT_DIR/$APP/Assets.xcassets"
PNG_DIR="$HOME/Desktop/MacSweep/PNG"

# Menu bar icon (MS sweep shape without background)
MENUBAR_PNG="$PNG_DIR/Menu bar icon.png"
if [ -f "$MENUBAR_PNG" ]; then
    MENUBAR_SET="$ASSETS_DIR/MenuBarIcon.imageset"
    mkdir -p "$MENUBAR_SET"
    sips -Z 18 "$MENUBAR_PNG" --out "$MENUBAR_SET/menubar.png" >/dev/null 2>&1
    sips -Z 36 "$MENUBAR_PNG" --out "$MENUBAR_SET/menubar@2x.png" >/dev/null 2>&1
    cat > "$MENUBAR_SET/Contents.json" << 'MBJSON'
{
  "images" : [
    { "filename" : "menubar.png", "idiom" : "universal", "scale" : "1x" },
    { "filename" : "menubar@2x.png", "idiom" : "universal", "scale" : "2x" }
  ],
  "info" : { "author" : "xcode", "version" : 1 },
  "properties" : { "template-rendering-intent" : "original" }
}
MBJSON
    echo "  ✓ MenuBarIcon asset added"
fi

# Sidebar brand logo (MS icon without text)
BRAND_PNG="$PNG_DIR/Application Ican witout MacSweep.png"
if [ -f "$BRAND_PNG" ]; then
    BRAND_SET="$ASSETS_DIR/BrandLogo.imageset"
    mkdir -p "$BRAND_SET"
    sips -Z 128 "$BRAND_PNG" --out "$BRAND_SET/brand.png" >/dev/null 2>&1
    sips -Z 256 "$BRAND_PNG" --out "$BRAND_SET/brand@2x.png" >/dev/null 2>&1
    cat > "$BRAND_SET/Contents.json" << 'BRJSON'
{
  "images" : [
    { "filename" : "brand.png", "idiom" : "universal", "scale" : "1x" },
    { "filename" : "brand@2x.png", "idiom" : "universal", "scale" : "2x" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
BRJSON
    echo "  ✓ BrandLogo asset added"
fi

echo ""

# ── Build the app ───────────────────────────────────────────
echo "  🔨 Building $APP.app for $BUILD_ARCH (this takes 1-2 minutes)..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

set +e  # Temporarily disable exit on error
set -o pipefail
xcodebuild \
    -project "$APP.xcodeproj" \
    -scheme "$APP" \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    -arch "$BUILD_ARCH" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    ONLY_ACTIVE_ARCH=NO \
    clean build \
    2>&1 | tee "$BUILD_DIR/build.log" | grep -E "(error:|warning:|Build succeeded|Build failed|Compiling)"
BUILD_RESULT=${PIPESTATUS[0]}
set -e

# Check xcodebuild exit code
if [ "$BUILD_RESULT" -ne 0 ]; then
    echo ""
    echo "  ✗ Build failed with errors! Check $BUILD_DIR/build.log for details."
    echo "    Or open the project in Xcode: open $APP.xcodeproj"
    exit 1
fi

# Find the built .app
APP_PATH=$(find "$BUILD_DIR" -name "$APP.app" -type d | head -1)

# Verify the executable actually exists inside the .app
if [ -z "$APP_PATH" ] || [ ! -f "$APP_PATH/Contents/MacOS/$APP" ]; then
    echo ""
    echo "  ✗ Build failed — executable not produced."
    echo "    Check errors above or open in Xcode: open $APP.xcodeproj"
    if [ -f "$BUILD_DIR/build.log" ]; then
        echo ""
        echo "  Last errors from build log:"
        grep "error:" "$BUILD_DIR/build.log" | tail -5
    fi
    exit 1
fi

echo ""
echo "  ✅ Build succeeded: $APP_PATH"

# ── Post-build: icon + single-instance ─────────────────────
ICNS_PATH="$SCRIPT_DIR/$APP/AppIcon.icns"
PLIST="$APP_PATH/Contents/Info.plist"

if [ -f "$ICNS_PATH" ]; then
    mkdir -p "$APP_PATH/Contents/Resources"
    cp "$ICNS_PATH" "$APP_PATH/Contents/Resources/AppIcon.icns"
    /usr/libexec/PlistBuddy -c "Set :CFBundleIconFile AppIcon" "$PLIST" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$PLIST" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Set :CFBundleIconName AppIcon" "$PLIST" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Add :CFBundleIconName string AppIcon" "$PLIST" 2>/dev/null || true
    echo "  ✓ App icon injected into bundle"
fi

# Prevent multiple instances
/usr/libexec/PlistBuddy -c "Set :LSMultipleInstancesProhibited true" "$PLIST" 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Add :LSMultipleInstancesProhibited bool true" "$PLIST" 2>/dev/null || true

# Force macOS to refresh the icon cache
touch "$APP_PATH"
echo "  ✓ Info.plist updated (icon + single-instance)"
echo ""

# ── Fix 3: Professional DMG with gradient background ───────
echo "  💿 Creating professional DMG installer..."
rm -rf "$DMG_DIR"
mkdir -p "$DMG_DIR"

DMG_STAGING="$BUILD_DIR/dmg_staging"
DMG_BG_DIR="$BUILD_DIR/dmg_bg"
rm -rf "$DMG_STAGING" "$DMG_BG_DIR"
mkdir -p "$DMG_STAGING/.background"

# Copy app to staging
cp -R "$APP_PATH" "$DMG_STAGING/"

# Create symlink to Applications folder
ln -s /Applications "$DMG_STAGING/Applications"

DMG_NAME="${APP}-${VERSION}.dmg"
DMG_TEMP="$BUILD_DIR/${APP}-temp.dmg"
DMG_PATH="$DMG_DIR/$DMG_NAME"

# ── Generate branded DMG background (600×400) ───────────────
echo "  🎨 Generating DMG background..."
BUILD_DIR="$BUILD_DIR" python3 - <<'PYEOF'
import struct, zlib, os, sys
import math

WIDTH, HEIGHT = 600, 400

TOP_BG = (30, 36, 47)       # #1E242F
BOTTOM_BG = (8, 13, 24)     # #080D18
BRAND = (22, 150, 119)      # #169677
BRAND_BRIGHT = (42, 209, 172)

def blend(base, tint, alpha):
    """Alpha blend tint color over base (both RGB tuples)."""
    a = max(0.0, min(1.0, alpha))
    return (
        int(base[0] * (1.0 - a) + tint[0] * a),
        int(base[1] * (1.0 - a) + tint[1] * a),
        int(base[2] * (1.0 - a) + tint[2] * a),
    )

def radial_alpha(x, y, cx, cy, rx, ry, power=2.0):
    dx = (x - cx) / max(1.0, rx)
    dy = (y - cy) / max(1.0, ry)
    d = math.sqrt(dx * dx + dy * dy)
    if d >= 1.0:
        return 0.0
    return (1.0 - d) ** power

def make_pixel(x, y):
    # Base vertical gradient
    t = y / (HEIGHT - 1)
    base = (
        int(TOP_BG[0] + (BOTTOM_BG[0] - TOP_BG[0]) * t),
        int(TOP_BG[1] + (BOTTOM_BG[1] - TOP_BG[1]) * t),
        int(TOP_BG[2] + (BOTTOM_BG[2] - TOP_BG[2]) * t),
    )

    # Subtle grid to match app surfaces
    if x % 80 == 0 or y % 80 == 0:
        base = blend(base, (73, 79, 90), 0.12)

    # Global ambient green glow
    ambient = radial_alpha(x, y, WIDTH * 0.50, HEIGHT * 0.45, WIDTH * 0.62, HEIGHT * 0.78, 2.6)
    if ambient > 0:
        base = blend(base, BRAND, ambient * 0.22)

    # Drop-zone glows near app and Applications icons
    left_glow = radial_alpha(x, y, 160, 185, 95, 95, 2.1)
    right_glow = radial_alpha(x, y, 440, 185, 95, 95, 2.1)
    if left_glow > 0:
        base = blend(base, BRAND_BRIGHT, left_glow * 0.45)
    if right_glow > 0:
        base = blend(base, BRAND_BRIGHT, right_glow * 0.45)

    # Drag path beam between both icons
    if 230 <= x <= 370:
        d = abs(y - 185)
        if d <= 2:
            beam = (1.0 - d / 2.0) * 0.65
            base = blend(base, BRAND_BRIGHT, beam)

    # Small arrowhead near Applications side
    if 365 <= x <= 382:
        height = (x - 365) * 0.42
        if abs(y - 185) <= height:
            base = blend(base, BRAND_BRIGHT, 0.60)

    # Edge vignette for depth
    edge = min(x / WIDTH, (WIDTH - x) / WIDTH, y / HEIGHT, (HEIGHT - y) / HEIGHT)
    if edge < 0.12:
        base = blend(base, (5, 8, 14), (0.12 - edge) * 2.5)

    return bytes(base)

# Build PNG manually (no PIL needed)
raw_data = b''
for y in range(HEIGHT):
    raw_data += b'\x00'  # filter byte
    for x in range(WIDTH):
        raw_data += make_pixel(x, y)

def png_chunk(chunk_type, data):
    c = chunk_type + data
    return struct.pack('>I', len(data)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)

sig = b'\x89PNG\r\n\x1a\n'
ihdr = struct.pack('>IIBBBBB', WIDTH, HEIGHT, 8, 2, 0, 0, 0)
png = sig + png_chunk(b'IHDR', ihdr) + png_chunk(b'IDAT', zlib.compress(raw_data, 9)) + png_chunk(b'IEND', b'')

build_dir = os.environ.get("BUILD_DIR")
if not build_dir:
    print("BUILD_DIR is not set", file=sys.stderr)
    sys.exit(1)
bg_path = os.path.join(build_dir, 'dmg_staging', '.background', 'bg.png')
os.makedirs(os.path.dirname(bg_path), exist_ok=True)
with open(bg_path, 'wb') as f:
    f.write(png)
print(f"  Background: {len(png)} bytes → {bg_path}")
PYEOF

# ── Create writable DMG first (for AppleScript window customization) ──
echo "  📀 Creating writable DMG..."
set +e
CREATE_OUTPUT=$(hdiutil create \
    -volname "$APP" \
    -srcfolder "$DMG_STAGING" \
    -ov \
    -format UDRW \
    "$DMG_TEMP" \
    2>&1)
CREATE_RESULT=$?
set -e
echo "$CREATE_OUTPUT" | grep -v "^hdiutil:" || true

DMG_READY=0

if [ "$CREATE_RESULT" -eq 0 ] && [ -f "$DMG_TEMP" ]; then
    # ── Mount and customize with AppleScript ────────────────────
    echo "  🎨 Applying Finder window customization..."
    set +e
    HDIUTIL_OUTPUT=$(hdiutil attach -readwrite -noverify -noautoopen "$DMG_TEMP" 2>&1)
    ATTACH_RESULT=$?
    set -e
    echo "$HDIUTIL_OUTPUT"
    MOUNT_POINT=$(echo "$HDIUTIL_OUTPUT" | grep -o '/Volumes/.*' | head -1 || true)

    if [ "$ATTACH_RESULT" -eq 0 ] && [ -n "$MOUNT_POINT" ]; then
        echo "  Mounted at: $MOUNT_POINT"
        # Give Finder time to index the volume
        sleep 2

        osascript <<APPLESCRIPT
tell application "Finder"
    tell disk "$APP"
        open
        delay 1
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {-2000, -2000, -1400, -1600}
        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 104
        set text size of theViewOptions to 14
        try
            set background picture of theViewOptions to file ".background:bg.png"
        end try
        set position of item "$APP.app" of container window to {160, 185}
        set position of item "Applications" of container window to {440, 185}
        set the bounds of container window to {200, 120, 800, 520}
        update without registering applications
        delay 1
        close
    end tell
end tell
APPLESCRIPT

        # Unmount
        sync
        hdiutil detach "$MOUNT_POINT" -quiet 2>/dev/null || true
    else
        echo "  ⚠ Could not mount DMG for customization (DMG will still work)"
    fi

    # ── Convert to compressed final DMG ─────────────────────────
    echo "  📦 Compressing DMG (zlib-9)..."
    set +e
    CONVERT_OUTPUT=$(hdiutil convert \
        "$DMG_TEMP" \
        -format UDZO \
        -imagekey zlib-level=9 \
        -o "$DMG_PATH" \
        2>&1)
    CONVERT_RESULT=$?
    set -e
    echo "$CONVERT_OUTPUT"

    if [ "$CONVERT_RESULT" -eq 0 ] && [ -f "$DMG_PATH" ]; then
        DMG_READY=1
    else
        echo "  ⚠ DMG conversion failed, trying direct fallback..."
    fi
else
    echo "  ⚠ Writable DMG creation failed, using direct fallback..."
fi

# Fallback: create compressed DMG directly from staging
if [ "$DMG_READY" -eq 0 ]; then
    echo "  📦 Creating fallback compressed DMG..."
    rm -f "$DMG_PATH"
    set +e
    FALLBACK_OUTPUT=$(hdiutil create \
        -volname "$APP" \
        -srcfolder "$DMG_STAGING" \
        -ov \
        -format UDZO \
        "$DMG_PATH" \
        2>&1)
    FALLBACK_RESULT=$?
    set -e
    echo "$FALLBACK_OUTPUT"

    if [ "$FALLBACK_RESULT" -ne 0 ] || [ ! -f "$DMG_PATH" ]; then
        echo "  ✗ DMG creation failed."
        rm -f "$DMG_TEMP"
        exit 1
    fi
fi

# Clean up temp
rm -f "$DMG_TEMP"

echo ""
echo "  ╔══════════════════════════════════════════╗"
echo "  ║       ✅  MacSweep v${VERSION} — SUCCESS!       ║"
echo "  ╚══════════════════════════════════════════╝"
echo ""
echo "  DMG created: dist/$DMG_NAME"
echo "  Architecture: $BUILD_ARCH"
echo ""
echo "  To install:"
echo "  1. Open dist/$DMG_NAME"
echo "  2. Drag MacSweep to Applications"
echo "  3. Open MacSweep from Applications"
echo "  4. If blocked: System Settings > Privacy > Allow"
echo ""
echo "  Quick install (copy + allow + open):"
echo "  cp -R \"$APP_PATH\" /Applications/ && sudo xattr -cr /Applications/$APP.app && open /Applications/$APP.app"
echo ""

# Open the dist folder (non-fatal in headless sessions)
open "$DMG_DIR" >/dev/null 2>&1 || true
