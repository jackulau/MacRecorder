#!/bin/bash

# Create DMG installer for MacroRecorder
# This script creates a distributable .dmg file

APP_NAME="MacroRecorder"
APP_BUNDLE="build/${APP_NAME}.app"
DMG_NAME="${APP_NAME}-v1.1.0"
VOLUME_NAME="${APP_NAME}"
DMG_TEMP="${DMG_NAME}-temp.dmg"
DMG_FINAL="${DMG_NAME}.dmg"
STAGING_DIR="dmg_staging"

echo "🎁 Creating DMG installer for ${APP_NAME}..."

# Check if app bundle exists
if [ ! -d "$APP_BUNDLE" ]; then
    echo "❌ Error: $APP_BUNDLE not found. Please build the app first."
    exit 1
fi

# Clean up any existing DMG files and staging directory
rm -rf "$DMG_TEMP" "$DMG_FINAL" "$STAGING_DIR"

# Create staging directory
mkdir -p "$STAGING_DIR"

# Copy app bundle to staging directory
echo "📦 Copying ${APP_BUNDLE} to staging directory..."
cp -R "$APP_BUNDLE" "$STAGING_DIR/"

# Create symbolic link to Applications folder
echo "🔗 Creating Applications folder symlink..."
ln -s /Applications "$STAGING_DIR/Applications"

# Create a README
cat > "$STAGING_DIR/README.txt" << 'EOF'
MacroRecorder v1.1.0
====================

Thank you for downloading MacroRecorder!

Installation Instructions:
1. Drag MacroRecorder.app to the Applications folder
2. Open MacroRecorder from your Applications folder
3. Grant Accessibility permissions when prompted
   (System Settings → Privacy & Security → Accessibility)

Core Features:
- Record mouse clicks, movements, and keyboard input
- Playback macros at variable speeds
- Window-specific recording and playback
- Global hotkeys for quick access
- Save and load macros

New in v1.1.0:
- Customizable Hotkeys: Configure your own shortcuts
- Variable Delays & Random Intervals: Add dynamic timing
- Interactive Timeline Editor: Drag events to adjust timing
- AppleScript Integration: Execute scripts within macros
- Conditional Playback: If/else logic and loops
- Image-Based Positioning: Click on visual elements
- Macro Templates Library: Pre-built templates to get started
- Cloud Sync: Sync macros across devices via iCloud

Support:
For issues or questions, please visit the project repository.

Minimum Requirements:
- macOS 13.0 (Ventura) or later
- Accessibility permissions required
- iCloud account (for cloud sync feature)

Copyright © 2025. All rights reserved.
EOF

# Calculate size needed for DMG
echo "📏 Calculating size..."
SIZE=$(du -sk "$STAGING_DIR" | cut -f1)
SIZE=$((SIZE + 5000))  # Add 5MB buffer

# Create temporary DMG
echo "🔨 Creating temporary DMG..."
hdiutil create -srcfolder "$STAGING_DIR" \
    -volname "$VOLUME_NAME" \
    -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" \
    -format UDRW \
    -size ${SIZE}k \
    "$DMG_TEMP"

# Mount the temporary DMG
echo "💿 Mounting temporary DMG..."
DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "$DMG_TEMP" | grep -E '^/dev/' | sed 1q | awk '{print $1}')

# Wait for mount
sleep 2

# Get the mount point
MOUNT_POINT="/Volumes/$VOLUME_NAME"

# Set custom icon positions and window properties
echo "🎨 Customizing DMG window..."
osascript << EOF
tell application "Finder"
    tell disk "$VOLUME_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {100, 100, 700, 500}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 96
        set background color of viewOptions to {255, 255, 255}

        -- Position icons
        set position of item "${APP_NAME}.app" of container window to {150, 180}
        set position of item "Applications" of container window to {450, 180}

        -- Hide README from window view but keep in DMG
        set position of item "README.txt" of container window to {150, 350}

        -- Update and close
        update without registering applications
        delay 2
        close
    end tell
end tell
EOF

# Ensure everything is written
sync

# Unmount the temporary DMG
echo "💾 Unmounting temporary DMG..."
hdiutil detach "$DEVICE"

# Convert to final compressed DMG
echo "🗜️  Creating final compressed DMG..."
hdiutil convert "$DMG_TEMP" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$DMG_FINAL"

# Clean up
echo "🧹 Cleaning up..."
rm -rf "$DMG_TEMP" "$STAGING_DIR"

# Calculate final size
FINAL_SIZE=$(du -h "$DMG_FINAL" | cut -f1)

echo ""
echo "✅ DMG created successfully!"
echo "📦 File: $DMG_FINAL"
echo "📊 Size: $FINAL_SIZE"
echo ""
echo "🚀 Your DMG is ready for distribution!"
