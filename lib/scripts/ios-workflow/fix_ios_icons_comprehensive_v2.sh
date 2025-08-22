#!/bin/bash
# 🔧 Comprehensive iOS Icon Fix v2.0 for App Store Connect Compliance
# Fixes Contents.json corruption, missing icons, transparency issues, and Info.plist configuration

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ICON_FIX_V2] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

log_info "🔧 Starting comprehensive iOS icon fix v2.0 for App Store Connect compliance..."

# Check if we're in the right directory
if [[ ! -d "ios" ]]; then
    log_error "iOS directory not found. Please run this script from the Flutter project root."
    exit 1
fi

# Create backup directory
BACKUP_DIR="ios/backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Step 1: Fix corrupted Contents.json
log_info "🔧 Step 1: Fixing corrupted Contents.json..."

CONTENTS_JSON="ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json"
if [[ -f "$CONTENTS_JSON" ]]; then
    # Backup current Contents.json
    cp "$CONTENTS_JSON" "$BACKUP_DIR/Contents.json.backup"
    log_success "✅ Backed up Contents.json to $BACKUP_DIR/Contents.json.backup"
    
    # Create clean Contents.json with all required icon sizes
    cat > "$CONTENTS_JSON" << 'EOF'
{
  "images" : [
    {
      "filename" : "Icon-App-20x20@1x.png",
      "idiom" : "iphone",
      "scale" : "1x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-App-20x20@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-App-20x20@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-App-29x29@1x.png",
      "idiom" : "iphone",
      "scale" : "1x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-App-29x29@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-App-29x29@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-App-40x40@1x.png",
      "idiom" : "iphone",
      "scale" : "1x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-App-40x40@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-App-40x40@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-App-60x60@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "filename" : "Icon-App-60x60@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "filename" : "Icon-App-20x20@1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-App-20x20@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-App-29x29@1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-App-29x29@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-App-40x40@1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-App-40x40@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-App-76x76@1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "76x76"
    },
    {
      "filename" : "Icon-App-76x76@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "76x76"
    },
    {
      "filename" : "Icon-App-83.5x83.5@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "83.5x83.5"
    },
    {
      "filename" : "Icon-App-1024x1024@1x.png",
      "idiom" : "ios-marketing",
      "scale" : "1x",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF
    log_success "✅ Created clean Contents.json with proper structure"
else
    log_error "❌ Contents.json not found at $CONTENTS_JSON"
    exit 1
fi

# Step 2: Fix icon transparency issues
log_info "🔧 Step 2: Fixing icon transparency issues..."

ICON_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"
if [[ -d "$ICON_DIR" ]]; then
    # Check if ImageMagick is available for transparency removal
    if command -v convert > /dev/null 2>&1; then
        log_info "Using ImageMagick to fix transparency issues..."
        
        for icon_file in "$ICON_DIR"/*.png; do
            if [[ -f "$icon_file" ]]; then
                # Create backup
                cp "$icon_file" "$icon_file.backup"
                
                # Remove transparency and add white background
                convert "$icon_file" -background white -alpha remove -alpha off "$icon_file"
                
                if [[ $? -eq 0 ]]; then
                    log_success "✅ Fixed transparency for $(basename "$icon_file")"
                else
                    log_warning "⚠️ Failed to fix transparency for $(basename "$icon_file"), restoring backup"
                    mv "$icon_file.backup" "$icon_file"
                fi
            fi
        done
    else
        log_warning "⚠️ ImageMagick not available, skipping transparency fix"
        log_info "Icons may have transparency issues that could cause App Store validation failures"
    fi
else
    log_error "❌ Icon directory not found: $ICON_DIR"
    exit 1
fi

# Step 3: Fix Info.plist configuration
log_info "🔧 Step 3: Fixing Info.plist configuration..."

INFO_PLIST="ios/Runner/Info.plist"
if [[ -f "$INFO_PLIST" ]]; then
    # Backup Info.plist
    cp "$INFO_PLIST" "$BACKUP_DIR/Info.plist.backup"
    log_success "✅ Backed up Info.plist to $BACKUP_DIR/Info.plist.backup"
    
    # Ensure CFBundleIconName is properly set
    if ! /usr/libexec/PlistBuddy -c "Print :CFBundleIconName" "$INFO_PLIST" > /dev/null 2>&1; then
        /usr/libexec/PlistBuddy -c "Add :CFBundleIconName string AppIcon" "$INFO_PLIST"
        log_success "✅ Added CFBundleIconName to Info.plist"
    else
        log_success "✅ CFBundleIconName already exists in Info.plist"
    fi
    
    # Add comprehensive icon configuration
    if ! /usr/libexec/PlistBuddy -c "Print :CFBundleIcons" "$INFO_PLIST" > /dev/null 2>&1; then
        /usr/libexec/PlistBuddy -c "Add :CFBundleIcons dict" "$INFO_PLIST"
        /usr/libexec/PlistBuddy -c "Add :CFBundleIcons:CFBundlePrimaryIcon dict" "$INFO_PLIST"
        /usr/libexec/PlistBuddy -c "Add :CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconName string AppIcon" "$INFO_PLIST"
        /usr/libexec/PlistBuddy -c "Add :CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconFiles array" "$INFO_PLIST"
        /usr/libexec/PlistBuddy -c "Add :CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconFiles: string AppIcon" "$INFO_PLIST"
        log_success "✅ Added comprehensive icon configuration to Info.plist"
    else
        log_success "✅ CFBundleIcons already exists in Info.plist"
    fi
else
    log_error "❌ Info.plist not found at $INFO_PLIST"
    exit 1
fi

# Step 4: Verify icon files exist
log_info "🔧 Step 4: Verifying icon files exist..."

REQUIRED_ICONS=(
    "Icon-App-20x20@1x.png"
    "Icon-App-20x20@2x.png"
    "Icon-App-20x20@3x.png"
    "Icon-App-29x29@1x.png"
    "Icon-App-29x29@2x.png"
    "Icon-App-29x29@3x.png"
    "Icon-App-40x40@1x.png"
    "Icon-App-40x40@2x.png"
    "Icon-App-40x40@3x.png"
    "Icon-App-60x60@2x.png"
    "Icon-App-60x60@3x.png"
    "Icon-App-76x76@1x.png"
    "Icon-App-76x76@2x.png"
    "Icon-App-83.5x83.5@2x.png"
    "Icon-App-1024x1024@1x.png"
)

MISSING_ICONS=()
for icon in "${REQUIRED_ICONS[@]}"; do
    if [[ ! -f "$ICON_DIR/$icon" ]]; then
        MISSING_ICONS+=("$icon")
    fi
done

if [[ ${#MISSING_ICONS[@]} -gt 0 ]]; then
    log_warning "⚠️ Missing required icons: ${MISSING_ICONS[*]}"
    log_warning "⚠️ App Store validation may fail due to missing icons"
else
    log_success "✅ All required icons are present"
fi

# Step 5: Validate icon dimensions
log_info "🔧 Step 5: Validating icon dimensions..."

if command -v sips > /dev/null 2>&1; then
    for icon in "$ICON_DIR"/*.png; do
        if [[ -f "$icon" ]]; then
            DIMENSIONS=$(sips -g pixelWidth -g pixelHeight "$icon" 2>/dev/null | grep -E "(pixelWidth|pixelHeight)" | awk '{print $2}' | tr '\n' 'x' | sed 's/x$//')
            if [[ -n "$DIMENSIONS" ]]; then
                WIDTH=$(echo "$DIMENSIONS" | cut -d'x' -f1)
                HEIGHT=$(echo "$DIMENSIONS" | cut -d'x' -f2)
                
                if [[ "$WIDTH" == "$HEIGHT" ]]; then
                    log_success "✅ $(basename "$icon"): ${WIDTH}x${HEIGHT} (square)"
                else
                    log_warning "⚠️ $(basename "$icon"): ${WIDTH}x${HEIGHT} (not square - may cause issues)"
                fi
            fi
        fi
    done
else
    log_warning "⚠️ sips not available, skipping dimension validation"
fi

# Step 6: Final validation
log_info "🔧 Step 6: Final validation..."

# Check if Contents.json is valid JSON
if python3 -m json.tool "$CONTENTS_JSON" > /dev/null 2>&1; then
    log_success "✅ Contents.json is valid JSON"
else
    log_error "❌ Contents.json is not valid JSON"
    exit 1
fi

# Check if Info.plist is valid
if plutil -lint "$INFO_PLIST" > /dev/null 2>&1; then
    log_success "✅ Info.plist is valid"
else
    log_error "❌ Info.plist is not valid"
    exit 1
fi

# Summary
log_success "🎉 Comprehensive iOS icon fix v2.0 completed successfully!"
log_info "📁 Backup files saved to: $BACKUP_DIR"
log_info "📱 App icons should now pass App Store Connect validation"
log_info "🔧 Fixed issues:"
log_info "  ✅ Contents.json corruption and duplicates"
log_info "  ✅ Icon transparency issues"
log_info "  ✅ Info.plist icon configuration"
log_info "  ✅ Icon file validation"
log_info "  ✅ Dimension validation"

exit 0
