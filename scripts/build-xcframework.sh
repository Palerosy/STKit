#!/bin/bash
set -e

# STKit Static XCFramework Build Script (library format)
# Uses .a static libraries with proper Swift module support
# Builds for iOS Device, iOS Simulator, and macOS
# Usage: ./scripts/build-xcframework.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="/tmp/STKit-build"
DIST_DIR="$ROOT_DIR/dist"
DERIVED_DATA="$BUILD_DIR/DerivedData"

export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

ALL_XCFRAMEWORKS=("STKit" "STDOCX" "STExcel" "STTXT" "STPDF")
ALL_SCHEMES=("STDOCX" "STExcel" "STTXT" "STPDF")

echo "=== STKit Static XCFramework Builder (iOS + macOS) ==="
echo "Root: $ROOT_DIR"
echo ""

# Clean
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/libs/iphoneos" "$BUILD_DIR/libs/iphonesimulator" "$BUILD_DIR/libs/macosx" "$DIST_DIR"

# 1. Build for iOS Device
echo "[1/8] Building for iOS Device..."
cd "$ROOT_DIR"
for SCHEME in "${ALL_SCHEMES[@]}"; do
    xcodebuild build \
        -scheme "$SCHEME" \
        -destination "generic/platform=iOS" \
        -derivedDataPath "$DERIVED_DATA" \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        -configuration Release \
        -quiet 2>&1 | grep -E "^.*(error:.*|FAILED).*$" || true
done
echo "   Done"

# 2. Build for iOS Simulator
echo "[2/8] Building for iOS Simulator..."
for SCHEME in "${ALL_SCHEMES[@]}"; do
    xcodebuild build \
        -scheme "$SCHEME" \
        -destination "generic/platform=iOS Simulator" \
        -derivedDataPath "$DERIVED_DATA" \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        -configuration Release \
        -quiet 2>&1 | grep -E "^.*(error:.*|FAILED).*$" || true
done
echo "   Done"

# 3. Build for macOS
echo "[3/8] Building for macOS..."
for SCHEME in "${ALL_SCHEMES[@]}"; do
    xcodebuild build \
        -scheme "$SCHEME" \
        -destination "generic/platform=macOS" \
        -derivedDataPath "$DERIVED_DATA" \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        -configuration Release \
        -quiet 2>&1 | grep -E "^.*(error:.*|FAILED).*$" || true
done
echo "   Done"

# Helper paths
IOS_PRODUCTS="$DERIVED_DATA/Build/Products/Release-iphoneos"
SIM_PRODUCTS="$DERIVED_DATA/Build/Products/Release-iphonesimulator"
MAC_PRODUCTS="$DERIVED_DATA/Build/Products/Release"
INTERMEDIATES="$DERIVED_DATA/Build/Intermediates.noindex"

# 4. Verify build artifacts
echo "[4/8] Verifying build artifacts..."
for PLATFORM in "iphoneos" "iphonesimulator" "macosx"; do
    if [ "$PLATFORM" = "macosx" ]; then
        PRODUCTS="$DERIVED_DATA/Build/Products/Release"
    else
        PRODUCTS="$DERIVED_DATA/Build/Products/Release-$PLATFORM"
    fi
    echo "   === $PLATFORM ==="
    for TARGET in "STKit" "STDOCX" "STExcel" "STTXT" "STPDF" "ZIPFoundation" ; do
        OBJ="$PRODUCTS/$TARGET.o"
        if [ -f "$OBJ" ]; then
            SIZE=$(ls -lh "$OBJ" | awk '{print $5}')
            echo "   $TARGET.o: $SIZE"
        else
            echo "   $TARGET.o: NOT FOUND"
        fi
    done
done

# 5. Create static libraries with headers
echo "[5/8] Creating static libraries..."

create_library() {
    local MODULE="$1"
    local PLATFORM="$2"
    local LIB_DIR="$BUILD_DIR/libs/$PLATFORM/$MODULE"
    local PRODUCTS

    if [ "$PLATFORM" = "macosx" ]; then
        PRODUCTS="$DERIVED_DATA/Build/Products/Release"
    else
        PRODUCTS="$DERIVED_DATA/Build/Products/Release-$PLATFORM"
    fi

    local OBJS_TO_MERGE=()

    case "$MODULE" in
        "STKit"|"STTXT"|"STExcel"|"STPDF")
            [ -f "$PRODUCTS/$MODULE.o" ] && OBJS_TO_MERGE+=("$PRODUCTS/$MODULE.o")
            ;;
        "STDOCX")
            [ -f "$PRODUCTS/$MODULE.o" ] && OBJS_TO_MERGE+=("$PRODUCTS/$MODULE.o")
            [ -f "$PRODUCTS/ZIPFoundation.o" ] && OBJS_TO_MERGE+=("$PRODUCTS/ZIPFoundation.o")
            ;;
    esac

    if [ ${#OBJS_TO_MERGE[@]} -eq 0 ]; then
        echo "   ERROR: No .o files found for $MODULE ($PLATFORM)"
        return 1
    fi

    # Create directory structure — use module subdirectory to avoid modulemap collisions
    mkdir -p "$LIB_DIR/Headers/$MODULE"

    # Create static library
    libtool -static -o "$LIB_DIR/lib${MODULE}.a" "${OBJS_TO_MERGE[@]}" 2>/dev/null

    local LIB_SIZE=$(ls -lh "$LIB_DIR/lib${MODULE}.a" | awk '{print $5}')

    # Copy swiftmodule (swiftinterface files)
    local SM="$PRODUCTS/$MODULE.swiftmodule"
    if [ -d "$SM" ]; then
        cp -R "$SM" "$LIB_DIR/$MODULE.swiftmodule"
    fi

    local IFACE_COUNT=$(ls "$LIB_DIR/$MODULE.swiftmodule/"*.swiftinterface 2>/dev/null | wc -l | tr -d ' ')

    # Find and copy -Swift.h header
    local HEADER=""
    if [ "$PLATFORM" = "iphoneos" ]; then
        HEADER=$(find "$INTERMEDIATES" -name "${MODULE}-Swift.h" -path "*/Release-iphoneos/*" -path "*/arm64/*" 2>/dev/null | head -1)
    elif [ "$PLATFORM" = "iphonesimulator" ]; then
        HEADER=$(find "$INTERMEDIATES" -name "${MODULE}-Swift.h" -path "*/Release-iphonesimulator/*" -path "*/arm64/*" 2>/dev/null | head -1)
    else
        HEADER=$(find "$INTERMEDIATES" -name "${MODULE}-Swift.h" -path "*/Release/*" -path "*/arm64/*" 2>/dev/null | grep -v "Release-" | head -1)
    fi
    if [ -n "$HEADER" ]; then
        cp "$HEADER" "$LIB_DIR/Headers/$MODULE/$MODULE-Swift.h"
    fi

    # Create module.modulemap inside module subdirectory
    cat > "$LIB_DIR/Headers/$MODULE/module.modulemap" << EOF
module $MODULE {
    header "$MODULE-Swift.h"
    export *
}
EOF

    echo "   $MODULE ($PLATFORM): $LIB_SIZE, $IFACE_COUNT swiftinterface files"
    return 0
}

for PLATFORM in "iphoneos" "iphonesimulator" "macosx"; do
    for MODULE in "${ALL_XCFRAMEWORKS[@]}"; do
        create_library "$MODULE" "$PLATFORM"
    done
done

# 6. Create XCFrameworks (library format)
echo "[6/8] Creating XCFrameworks..."
for MODULE in "${ALL_XCFRAMEWORKS[@]}"; do
    IOS_DIR="$BUILD_DIR/libs/iphoneos/$MODULE"
    SIM_DIR="$BUILD_DIR/libs/iphonesimulator/$MODULE"
    MAC_DIR="$BUILD_DIR/libs/macosx/$MODULE"

    rm -rf "$BUILD_DIR/$MODULE.xcframework"
    xcodebuild -create-xcframework \
        -library "$IOS_DIR/lib${MODULE}.a" \
        -headers "$IOS_DIR/Headers" \
        -library "$SIM_DIR/lib${MODULE}.a" \
        -headers "$SIM_DIR/Headers" \
        -library "$MAC_DIR/lib${MODULE}.a" \
        -headers "$MAC_DIR/Headers" \
        -output "$BUILD_DIR/$MODULE.xcframework"

    # Add Swift module files to each slice
    for SLICE_DIR in "$BUILD_DIR/$MODULE.xcframework"/*/; do
        SLICE_NAME=$(basename "$SLICE_DIR")
        # Determine which platform this slice is for
        if [[ "$SLICE_NAME" == *"ios-arm64_x86_64-simulator"* ]] || [[ "$SLICE_NAME" == *"ios-arm64-simulator"* ]]; then
            SRC_SM="$SIM_DIR/$MODULE.swiftmodule"
        elif [[ "$SLICE_NAME" == *"ios-arm64"* ]]; then
            SRC_SM="$IOS_DIR/$MODULE.swiftmodule"
        elif [[ "$SLICE_NAME" == *"macos"* ]]; then
            SRC_SM="$MAC_DIR/$MODULE.swiftmodule"
        else
            continue
        fi

        if [ -d "$SRC_SM" ]; then
            cp -R "$SRC_SM" "$SLICE_DIR/$MODULE.swiftmodule"
            echo "   Added $MODULE.swiftmodule to $SLICE_NAME"
        fi
    done

    echo "   $MODULE.xcframework created (iOS + macOS)"
done

# 7. Embed resources and package
echo "[7/8] Packaging..."
for MODULE in "${ALL_XCFRAMEWORKS[@]}"; do
    local_name="$MODULE"

    # SPM resource bundles use PackageName_TargetName pattern
    RESOURCE_BUNDLE=$(find "$DERIVED_DATA" -name "STKit_${local_name}.bundle" -path "*/Release-iphoneos/*" 2>/dev/null | head -1)
    if [ -z "$RESOURCE_BUNDLE" ]; then
        RESOURCE_BUNDLE=$(find "$DERIVED_DATA" -name "${local_name}_${local_name}.bundle" -path "*/Release-iphoneos/*" 2>/dev/null | head -1)
    fi
    if [ -n "$RESOURCE_BUNDLE" ]; then
        BUNDLE_NAME=$(basename "$RESOURCE_BUNDLE")
        for SLICE_DIR in "$BUILD_DIR/$MODULE.xcframework"/*/; do
            [ -d "$SLICE_DIR" ] && cp -RL "$RESOURCE_BUNDLE" "$SLICE_DIR/$BUNDLE_NAME"
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

# 8. Compute checksums
echo "[8/8] Computing checksums..."
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
