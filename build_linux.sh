#!/bin/bash

# Life Plans - Linux Build Script
# Creates both AppImage and .deb packages

set -e

echo "Building Life Plans for Linux..."

# Check if we're on Linux
if [ "$(uname)" != "Linux" ]; then
    echo "Error: This script must be run on Linux"
    exit 1
fi

# Navigate to project directory
cd "$(dirname "$0")"

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Build Linux release
echo "Building Linux release..."
flutter build linux --release

# Create output directory
OUTPUT_DIR="build/linux/packages"
mkdir -p "$OUTPUT_DIR"

# Get the bundle directory
BUNDLE_DIR="build/linux/x64/release/bundle"
APP_NAME="life_plans"

# Create .deb package
echo "Creating .deb package..."
mkdir -p "$OUTPUT_DIR/deb"
mkdir -p "$OUTPUT_DIR/deb/DEBIAN"
mkdir -p "$OUTPUT_DIR/deb/usr/bin"
mkdir -p "$OUTPUT_DIR/deb/usr/lib/$APP_NAME"
mkdir -p "$OUTPUT_DIR/deb/usr/share/applications"
mkdir -p "$OUTPUT_DIR/deb/usr/share/icons/hicolor/256x256/apps"

# Copy files
cp -r "$BUNDLE_DIR/"* "$OUTPUT_DIR/deb/usr/lib/$APP_NAME/"
cp "$BUNDLE_DIR/$APP_NAME" "$OUTPUT_DIR/deb/usr/bin/$APP_NAME"

# Create control file
cat > "$OUTPUT_DIR/deb/DEBIAN/control" << 'EOF'
Package: life-plans
Version: 1.0.0
Section: utils
Priority: optional
Architecture: amd64
Depends: libc6 (>= 2.28), libgtk-3-0 (>= 3.22.29)
Maintainer: Life Plans Team
Description: A free and open source task scheduler app
EOF

# Create desktop file
cat > "$OUTPUT_DIR/deb/usr/share/applications/$APP_NAME.desktop" << 'EOF'
[Desktop Entry]
Name=Life Plans
Comment=A free and open source task scheduler app
Exec=/usr/bin/life_plans
Icon=/usr/lib/life_plans/data/flutter_assets/app_icon.png
Terminal=false
Type=Application
Categories=Utility;Office;
EOF

# Build .deb
dpkg-deb --build "$OUTPUT_DIR/deb" "$OUTPUT_DIR/life_plans_1.0.0_amd64.deb"
echo "Created: $OUTPUT_DIR/life_plans_1.0.0_amd64.deb"

# Create AppImage (requires appimagetool)
echo "Creating AppImage..."
mkdir -p "$OUTPUT_DIR/appimage"

# AppRun script
cat > "$OUTPUT_DIR/AppRun" << 'EOF'
#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"
export PATH="${HERE}/usr/bin:${PATH}"
export LD_LIBRARY_PATH="${HERE}/usr/lib:${LD_LIBRARY_PATH}"
exec "${HERE}/usr/bin/life_plans" "$@"
EOF
chmod +x "$OUTPUT_DIR/AppRun"

# AppImage directory structure
mkdir -p "$OUTPUT_DIR/appimage/usr/bin"
mkdir -p "$OUTPUT_DIR/appimage/usr/lib"
mkdir -p "$OUTPUT_DIR/appimage/usr/share/icons/hicolor/256x256/apps"

# Copy bundle contents
cp -r "$BUNDLE_DIR/"* "$OUTPUT_DIR/appimage/usr/lib/$APP_NAME/"
cp "$BUNDLE_DIR/$APP_NAME" "$OUTPUT_DIR/appimage/usr/bin/$APP_NAME"

# Copy AppRun
cp "$OUTPUT_DIR/AppRun" "$OUTPUT_DIR/appimage/"

# Copy icon if exists
if [ -f "$BUNDLE_DIR/data/flutter_assets/app_icon.png" ]; then
    cp "$BUNDLE_DIR/data/flutter_assets/app_icon.png" "$OUTPUT_DIR/appimage/"
fi

# Create .desktop file for AppImage
cp "$OUTPUT_DIR/deb/usr/share/applications/$APP_NAME.desktop" "$OUTPUT_DIR/appimage/"

# Check if appimagetool is available
if command -v appimagetool &> /dev/null; then
    cd "$OUTPUT_DIR/appimage"
    appimagetool AppDir "$OUTPUT_DIR/LifePlans_1.0.0_amd64.AppImage"
    echo "Created: $OUTPUT_DIR/LifePlans_1.0.0_amd64.AppImage"
else
    echo "Warning: appimagetool not found. AppImage not created."
    echo "To create AppImage, install AppImageTool:"
    echo "  wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
    echo "  chmod +x appimagetool-x86_64.AppImage"
    echo "  sudo mv appimagetool-x86_64.AppImage /usr/local/bin/appimagetool"
    echo ""
    echo "Then run: appimagetool appimage LifePlans_1.0.0_amd64.AppImage"
fi

echo ""
echo "Build complete!"
echo "Output files in: $OUTPUT_DIR"
ls -la "$OUTPUT_DIR"
