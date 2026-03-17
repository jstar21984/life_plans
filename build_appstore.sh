#!/bin/bash

# Life Plans - iOS App Store Build Script
# Run this on macOS with Xcode installed

set -e

echo "=========================================="
echo "Life Plans - iOS App Store Build Script"
echo "=========================================="
echo ""

# Check if we're on macOS
if [ "$(uname)" != "Darwin" ]; then
    echo "Error: This script must be run on macOS"
    exit 1
fi

# Navigate to project directory
cd "$(dirname "$0")"

# Check for Apple Developer account
echo "Checking prerequisites..."
if ! command -v xcodegen &> /dev/null; then
    echo "Note: xcodegen not found, using existing project"
fi

# Get dependencies
echo "Getting Flutter dependencies..."
flutter pub get

# Build for iOS simulator first to verify
echo ""
echo "Step 1: Building for iOS Simulator..."
flutter build ios --simulator --no-codesign

# Build for App Store
echo ""
echo "Step 2: Building for App Store (Release)..."
flutter build ios --release

echo ""
echo "=========================================="
echo "Build Complete!"
echo "=========================================="
echo ""
echo "Next steps to submit to App Store:"
echo ""
echo "1. Open Xcode and sign in with your Apple Developer account:"
echo "   Xcode > Settings > Accounts"
echo ""
echo "2. Update the bundle identifier if needed in:"
echo "   ios/Runner.xcodeproj"
echo ""
echo "3. Create an App Store listing in App Store Connect:"
echo "   https://appstoreconnect.apple.com"
echo ""
echo "4. Upload the build using Xcode:"
echo "   - Open ios/Runner.xcworkspace in Xcode"
echo "   - Select 'Any iOS Device (arm64)' as target"
echo "   - Product > Archive"
echo "   - Distribute App > App Store Connect"
echo ""
echo "5. Or use Transporter app to upload the .ipa file"
echo ""
echo "The built app is located at:"
echo "   build/ios/ipa/"
echo ""
