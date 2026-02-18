#!/bin/bash
set -e

# STKit Static XCFramework Build Script (framework format)
# SwiftDocX sources are compiled as part of STDOCX — no separate module
# Usage: ./scripts/build-xcframework.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="/tmp/STKit-build"
DIST_DIR="$ROOT_DIR/dist"
DERIVED_DATA="$BUILD_DIR/DerivedData"

export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

ALL_XCFRAMEWORKS=("STKit" "STDOCX" "STExcel" "STTXT")

echo "=== STKit Static XCFramework Builder ==="
echo "Root: $ROOT_DIR"
echo ""

# Clean
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/frameworks/iphoneos" "$BUILD_DIR/frameworks/iphonesimulator" "$DIST_DIR"

# 1. Build for iOS Device
echo "[1/7] Building for iOS Device..."
cd "$ROOT_DIR"
xcodebuild build \
    -scheme "STDOCX" \
    -destination "generic/platform=iOS" \
    -derivedDataPath "$DERIVED_DATA" \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    -configuration Release \
    -quiet 2>&1 | grep -E "^.*(error:.*|FAILED).*$" || true

xcodebuild build \
    -scheme "STExcel" \
    -destination "generic/platform=iOS" \
    -derivedDataPath "$DERIVED_DATA" \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    -configuration Release \
    -quiet 2>&1 | grep -E "^.*(error:.*|FAILED).*$" || true

xcodebuild build \
    -scheme "STTXT" \
    -destination "generic/platform=iOS" \
    -derivedDataPath "$DERIVED_DATA" \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    -configuration Release \
    -quiet 2>&1 | grep -E "^.*(error:.*|FAILED).*$" || true
echo "   Done"

# 2. Build for iOS Simulator
echo "[2/7] Building for iOS Simulator..."
xcodebuild build \
    -scheme "STDOCX" \
    -destination "generic/platform=iOS Simulator" \
    -derivedDataPath "$DERIVED_DATA" \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    -configuration Release \
    -quiet 2>&1 | grep -E "^.*(error:.*|FAILED).*$" || true

xcodebuild build \
    -scheme "STExcel" \
    -destination "generic/platform=iOS Simulator" \
    -derivedDataPath "$DERIVED_DATA" \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    -configuration Release \
    -quiet 2>&1 | grep -E "^.*(error:.*|FAILED).*$" || true

xcodebuild build \
    -scheme "STTXT" \
    -destination "generic/platform=iOS Simulator" \
    -derivedDataPath "$DERIVED_DATA" \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    -configuration Release \
    -quiet 2>&1 | grep -E "^.*(error:.*|FAILED).*$" || true
echo "   Done"

# Helper paths
IOS_PRODUCTS="$DERIVED_DATA/Build/Products/Release-iphoneos"
SIM_PRODUCTS="$DERIVED_DATA/Build/Products/Release-iphonesimulator"
IOS_INTERMEDIATES="$DERIVED_DATA/Build/Intermediates.noindex"
SIM_INTERMEDIATES="$DERIVED_DATA/Build/Intermediates.noindex"

# 3. Verify build artifacts
echo "[3/7] Verifying build artifacts..."
for PLATFORM in "iphoneos" "iphonesimulator"; do
    PRODUCTS="$DERIVED_DATA/Build/Products/Release-$PLATFORM"
    echo "   === $PLATFORM ==="
    for TARGET in "STKit" "STDOCX" "STExcel" "STTXT" "ZIPFoundation" ; do
        OBJ="$PRODUCTS/$TARGET.o"
        if [ -f "$OBJ" ]; then
            SIZE=$(ls -lh "$OBJ" | awk '{print $5}')
            echo "   $TARGET.o: $SIZE"
        else
            echo "   $TARGET.o: NOT FOUND"
        fi
    done
done

# 4. Create framework bundles
echo "[4/7] Creating framework bundles..."

create_framework() {
    local MODULE="$1"
    local PLATFORM="$2"
    local FW_DIR="$BUILD_DIR/frameworks/$PLATFORM/$MODULE.framework"
    local PRODUCTS="$DERIVED_DATA/Build/Products/Release-$PLATFORM"

    mkdir -p "$FW_DIR/Modules/$MODULE.swiftmodule" "$FW_DIR/Headers"

    local OBJS_TO_MERGE=()
    local SOURCE_NAME="$MODULE"

    case "$MODULE" in
        "STKit"|"STTXT"|"STExcel")
            [ -f "$PRODUCTS/$MODULE.o" ] && OBJS_TO_MERGE+=("$PRODUCTS/$MODULE.o")
            ;;
        "STDOCX")
            # Embed ZIPFoundation.o into STDOCX so it is self-contained.
            # STExcel's ZIPFoundation references are resolved at app link-time from STDOCX.
            [ -f "$PRODUCTS/$MODULE.o" ] && OBJS_TO_MERGE+=("$PRODUCTS/$MODULE.o")
            [ -f "$PRODUCTS/ZIPFoundation.o" ] && OBJS_TO_MERGE+=("$PRODUCTS/ZIPFoundation.o")
            ;;
    esac

    if [ ${#OBJS_TO_MERGE[@]} -eq 0 ]; then
        echo "   ERROR: No .o files found for $MODULE ($PLATFORM)"
        return 1
    fi

    libtool -static -o "$FW_DIR/$MODULE" "${OBJS_TO_MERGE[@]}" 2>/dev/null

    local LIB_SIZE=$(ls -lh "$FW_DIR/$MODULE" | awk '{print $5}')

    # Copy swiftinterface files
    local SM="$PRODUCTS/$SOURCE_NAME.swiftmodule"
    if [ -d "$SM" ]; then
        for f in "$SM"/*.swiftinterface "$SM"/*.private.swiftinterface "$SM"/*.package.swiftinterface "$SM"/*.swiftdoc; do
            [ -f "$f" ] && cp "$f" "$FW_DIR/Modules/$MODULE.swiftmodule/"
        done
    fi

    local IFACE_COUNT=$(ls "$FW_DIR/Modules/$MODULE.swiftmodule/"*.swiftinterface 2>/dev/null | wc -l | tr -d ' ')

    # Find and copy -Swift.h header
    local HEADER=""
    if [ "$PLATFORM" = "iphoneos" ]; then
        HEADER=$(find "$IOS_INTERMEDIATES" -name "${SOURCE_NAME}-Swift.h" -path "*/Release-iphoneos/*" -path "*/arm64/*" 2>/dev/null | head -1)
    else
        HEADER=$(find "$SIM_INTERMEDIATES" -name "${SOURCE_NAME}-Swift.h" -path "*/Release-iphonesimulator/*" -path "*/arm64/*" 2>/dev/null | head -1)
    fi
    if [ -n "$HEADER" ]; then
        cp "$HEADER" "$FW_DIR/Headers/$MODULE-Swift.h"
    fi

    # Create module.modulemap
    cat > "$FW_DIR/Modules/module.modulemap" << EOF
framework module $MODULE {
    header "$MODULE-Swift.h"
    export *
}
EOF

    # Create Info.plist
    local BUNDLE_ID="${MODULE}"
    [ "$MODULE" = "_ZIPFoundation" ] && BUNDLE_ID="ZIPFoundation"
    cat > "$FW_DIR/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${MODULE}</string>
    <key>CFBundleIdentifier</key>
    <string>com.stkit.${BUNDLE_ID}</string>
    <key>CFBundleName</key>
    <string>${MODULE}</string>
    <key>CFBundleVersion</key>
    <string>0.7.17</string>
    <key>CFBundleShortVersionString</key>
    <string>0.7.17</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>MinimumOSVersion</key>
    <string>16.0</string>
    <key>CFBundleSupportedPlatforms</key>
    <array>
        <string>iPhoneOS</string>
    </array>
    <key>UIDeviceFamily</key>
    <array>
        <integer>1</integer>
        <integer>2</integer>
    </array>
</dict>
</plist>
PLIST

    echo "   $MODULE ($PLATFORM): $LIB_SIZE, $IFACE_COUNT swiftinterface files"
    return 0
}

for PLATFORM in "iphoneos" "iphonesimulator"; do
    for MODULE in "${ALL_XCFRAMEWORKS[@]}"; do
        create_framework "$MODULE" "$PLATFORM"
    done
done

# 5. Create XCFrameworks
echo "[5/7] Creating XCFrameworks..."
for MODULE in "${ALL_XCFRAMEWORKS[@]}"; do
    IOS_FW="$BUILD_DIR/frameworks/iphoneos/$MODULE.framework"
    SIM_FW="$BUILD_DIR/frameworks/iphonesimulator/$MODULE.framework"

    rm -rf "$BUILD_DIR/$MODULE.xcframework"
    xcodebuild -create-xcframework \
        -framework "$IOS_FW" \
        -framework "$SIM_FW" \
        -output "$BUILD_DIR/$MODULE.xcframework"

    echo "   $MODULE.xcframework created"
done

# 6. Embed resources and package
echo "[6/7] Packaging..."
for MODULE in "${ALL_XCFRAMEWORKS[@]}"; do
    local_name="$MODULE"
    [ "$MODULE" = "_ZIPFoundation" ] && local_name="ZIPFoundation"

    # SPM resource bundles use PackageName_TargetName pattern
    RESOURCE_BUNDLE=$(find "$DERIVED_DATA" -name "STKit_${local_name}.bundle" -path "*/Release-iphoneos/*" 2>/dev/null | head -1)
    if [ -z "$RESOURCE_BUNDLE" ]; then
        RESOURCE_BUNDLE=$(find "$DERIVED_DATA" -name "${local_name}_${local_name}.bundle" -path "*/Release-iphoneos/*" 2>/dev/null | head -1)
    fi
    if [ -n "$RESOURCE_BUNDLE" ]; then
        BUNDLE_NAME=$(basename "$RESOURCE_BUNDLE")
        for SLICE in "$BUILD_DIR/$MODULE.xcframework"/*/$MODULE.framework; do
            cp -RL "$RESOURCE_BUNDLE" "$SLICE/$BUNDLE_NAME"
        done
        echo "   $MODULE: resource bundle embedded ($BUNDLE_NAME)"
    fi

    cd "$BUILD_DIR"
    rm -f "$MODULE.xcframework.zip"
    zip -r -q "$MODULE.xcframework.zip" "$MODULE.xcframework"
    cp "$MODULE.xcframework.zip" "$DIST_DIR/"

    SIZE=$(ls -lh "$MODULE.xcframework.zip" | awk '{print $5}')
    echo "   $MODULE.xcframework.zip ($SIZE)"
done

# 7. Compute checksums
echo "[7/7] Computing checksums..."
cd "$ROOT_DIR"
echo ""
echo "=== Build Complete ==="
echo ""
echo "Checksums:"
for MODULE in "${ALL_XCFRAMEWORKS[@]}"; do
    CHECKSUM=$(swift package compute-checksum "$DIST_DIR/$MODULE.xcframework.zip")
    echo "  $MODULE: $CHECKSUM"
done
echo ""
echo "Output:"
ls -lh "$DIST_DIR"/*.zip
