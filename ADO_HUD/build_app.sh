#!/bin/bash

# Define App Name
APP_NAME="ADO_HUD"

# 1. Build release binary using Swift Package Manager
echo "🚀 Building release binary..."
swift build -c release

if [ $? -ne 0 ]; then
    echo "❌ Build failed."
    exit 1
fi

# 2. Create .app Bundle Structure
echo "📂 Creating $APP_NAME.app bundle..."
mkdir -p "$APP_NAME.app/Contents/MacOS"
mkdir -p "$APP_NAME.app/Contents/Resources"

# 3. Copy binary
echo "📦 Copying binary..."
cp ".build/release/$APP_NAME" "$APP_NAME.app/Contents/MacOS/$APP_NAME"

# 5. Handle App Icon
if [ -f "Icon.png" ]; then
    echo "🎨 Processing App Icon..."
    ICONSET_DIR="ADO_HUD.iconset"
    mkdir -p "$ICONSET_DIR"
    
    # Generate standard sizes with explicit PNG format
    sips -z 16 16     Icon.png --setProperty format png --out "${ICONSET_DIR}/icon_16x16.png" > /dev/null
    sips -z 32 32     Icon.png --setProperty format png --out "${ICONSET_DIR}/icon_16x16@2x.png" > /dev/null
    sips -z 32 32     Icon.png --setProperty format png --out "${ICONSET_DIR}/icon_32x32.png" > /dev/null
    sips -z 64 64     Icon.png --setProperty format png --out "${ICONSET_DIR}/icon_32x32@2x.png" > /dev/null
    sips -z 128 128   Icon.png --setProperty format png --out "${ICONSET_DIR}/icon_128x128.png" > /dev/null
    sips -z 256 256   Icon.png --setProperty format png --out "${ICONSET_DIR}/icon_128x128@2x.png" > /dev/null
    sips -z 256 256   Icon.png --setProperty format png --out "${ICONSET_DIR}/icon_256x256.png" > /dev/null
    sips -z 512 512   Icon.png --setProperty format png --out "${ICONSET_DIR}/icon_256x256@2x.png" > /dev/null
    sips -z 512 512   Icon.png --setProperty format png --out "${ICONSET_DIR}/icon_512x512.png" > /dev/null
    sips -z 1024 1024 Icon.png --setProperty format png --out "${ICONSET_DIR}/icon_512x512@2x.png" > /dev/null
    
    # Create icns
    iconutil -c icns "$ICONSET_DIR" -o "$APP_NAME.app/Contents/Resources/AppIcon.icns"
    
    # Cleanup
    rm -rf "$ICONSET_DIR"
    echo "✅ AppIcon.icns created."
else
    echo "⚠️  Icon.png not found. Skipping icon generation."
fi

# 6. Create Info.plist
echo "📝 Generating Info.plist..."
cat <<EOF > "$APP_NAME.app/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.$APP_NAME</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
</dict>
</plist>
EOF

echo "✅ Done! $APP_NAME.app is ready in this directory."
echo "You can move '$APP_NAME.app' to your Applications folder or another Mac."
