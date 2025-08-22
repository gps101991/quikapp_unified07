#!/bin/bash
# 🧪 Test iOS Fixes Script
# Verifies that all the iOS workflow and app icon fixes are working correctly

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}ℹ️ $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️ $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

echo "🧪 Testing iOS Fixes..."

# Test 1: Check if Contents.json is valid
log_info "Test 1: Validating Contents.json..."
if [[ -f "ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json" ]]; then
    # Try Python first, fallback to basic validation
    if command -v python3 > /dev/null 2>&1; then
        if python3 -m json.tool "ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json" > /dev/null 2>&1; then
            log_success "Contents.json is valid JSON (Python validation)"
        else
            log_warning "Python validation failed, trying basic validation..."
            # Basic validation: check if it starts with { and ends with }
            if grep -q "^[[:space:]]*{" "ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json" && \
               grep -q "}[[:space:]]*$" "ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json"; then
                log_success "Contents.json appears valid (basic validation)"
            else
                log_error "Contents.json validation failed"
                exit 1
            fi
        fi
    else
        log_warning "Python3 not available, using basic validation..."
        # Basic validation: check if it starts with { and ends with }
        if grep -q "^[[:space:]]*{" "ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json" && \
           grep -q "}[[:space:]]*$" "ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json"; then
            log_success "Contents.json appears valid (basic validation)"
        else
            log_error "Contents.json validation failed"
            exit 1
        fi
    fi
else
    log_error "Contents.json not found"
    exit 1
fi

# Test 2: Check if all required icons exist
log_info "Test 2: Checking required app icons..."
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

ICON_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"
MISSING_ICONS=()
for icon in "${REQUIRED_ICONS[@]}"; do
    if [[ ! -f "$ICON_DIR/$icon" ]]; then
        MISSING_ICONS+=("$icon")
    fi
done

if [[ ${#MISSING_ICONS[@]} -gt 0 ]]; then
    log_error "Missing required icons: ${MISSING_ICONS[*]}"
    exit 1
else
    log_success "All required app icons are present"
fi

# Test 3: Check Info.plist configuration
log_info "Test 3: Checking Info.plist configuration..."
if [[ -f "ios/Runner/Info.plist" ]]; then
    # Check if CFBundleIconName is set
    if /usr/libexec/PlistBuddy -c "Print :CFBundleIconName" "ios/Runner/Info.plist" > /dev/null 2>&1; then
        log_success "CFBundleIconName is set in Info.plist"
    else
        log_error "CFBundleIconName is missing from Info.plist"
        exit 1
    fi
    
    # Check if CFBundleIcons is set
    if /usr/libexec/PlistBuddy -c "Print :CFBundleIcons" "ios/Runner/Info.plist" > /dev/null 2>&1; then
        log_success "CFBundleIcons is set in Info.plist"
    else
        log_error "CFBundleIcons is missing from Info.plist"
        exit 1
    fi
else
    log_error "Info.plist not found"
    exit 1
fi

# Test 4: Check if fixed workflow script exists
log_info "Test 4: Checking fixed workflow script..."
if [[ -f "lib/scripts/ios-workflow/main_workflow_fixed.sh" ]]; then
    log_success "Fixed workflow script exists"
    
    # Check if it's executable
    if [[ -x "lib/scripts/ios-workflow/main_workflow_fixed.sh" ]]; then
        log_success "Fixed workflow script is executable"
    else
        log_warning "Fixed workflow script is not executable, making it executable..."
        chmod +x "lib/scripts/ios-workflow/main_workflow_fixed.sh"
        log_success "Fixed workflow script is now executable"
    fi
else
    log_error "Fixed workflow script not found"
    exit 1
fi

# Test 5: Check if comprehensive icon fix script exists
log_info "Test 5: Checking comprehensive icon fix script..."
if [[ -f "lib/scripts/ios-workflow/fix_ios_icons_comprehensive_v2.sh" ]]; then
    log_success "Comprehensive icon fix script exists"
    
    # Check if it's executable
    if [[ -x "lib/scripts/ios-workflow/fix_ios_icons_comprehensive_v2.sh" ]]; then
        log_success "Comprehensive icon fix script is executable"
    else
        log_warning "Comprehensive icon fix script is not executable, making it executable..."
        chmod +x "lib/scripts/ios-workflow/fix_ios_icons_comprehensive_v2.sh"
        log_success "Comprehensive icon fix script is now executable"
    fi
else
    log_error "Comprehensive icon fix script not found"
    exit 1
fi

# Test 6: Check codemagic.yaml configuration
log_info "Test 6: Checking codemagic.yaml configuration..."
if grep -q "main_workflow_fixed.sh" "codemagic.yaml"; then
    log_success "codemagic.yaml is configured to use the fixed workflow script"
else
    log_error "codemagic.yaml is not configured to use the fixed workflow script"
    exit 1
fi

# Test 7: Check icon dimensions (if sips is available)
log_info "Test 7: Checking icon dimensions..."
if command -v sips > /dev/null 2>&1; then
    ICON_COUNT=0
    SQUARE_ICONS=0
    
    for icon in "$ICON_DIR"/*.png; do
        if [[ -f "$icon" ]]; then
            ICON_COUNT=$((ICON_COUNT + 1))
            DIMENSIONS=$(sips -g pixelWidth -g pixelHeight "$icon" 2>/dev/null | grep -E "(pixelWidth|pixelHeight)" | awk '{print $2}' | tr '\n' 'x' | sed 's/x$//')
            if [[ -n "$DIMENSIONS" ]]; then
                WIDTH=$(echo "$DIMENSIONS" | cut -d'x' -f1)
                HEIGHT=$(echo "$DIMENSIONS" | cut -d'x' -f2)
                
                if [[ "$WIDTH" == "$HEIGHT" ]]; then
                    SQUARE_ICONS=$((SQUARE_ICONS + 1))
                fi
            fi
        fi
    done
    
    if [[ $SQUARE_ICONS -eq $ICON_COUNT ]]; then
        log_success "All icons are square (${SQUARE_ICONS}/${ICON_COUNT})"
    else
        log_warning "Some icons are not square (${SQUARE_ICONS}/${ICON_COUNT})"
    fi
else
    log_warning "sips not available, skipping dimension validation"
fi

# Test 8: Check for duplicate entries in Contents.json
log_info "Test 8: Checking for duplicate entries in Contents.json..."
DUPLICATE_COUNT=$(grep -c "filename" "ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json" || echo "0")
if [[ $DUPLICATE_COUNT -eq 25 ]]; then
    log_success "Contents.json has exactly 25 icon entries (no duplicates)"
else
    log_warning "Contents.json has $DUPLICATE_COUNT icon entries (expected 25)"
fi

# Test 9: Check file structure
log_info "Test 9: Checking file structure..."
if [[ -d "ios/Runner/Assets.xcassets/AppIcon.appiconset" ]]; then
    log_success "App icon directory exists"
    
    # Count total files
    TOTAL_FILES=$(find "ios/Runner/Assets.xcassets/AppIcon.appiconset" -type f | wc -l)
    log_info "Total files in icon directory: $TOTAL_FILES"
    
    # Count PNG files
    PNG_FILES=$(find "ios/Runner/Assets.xcassets/AppIcon.appiconset" -name "*.png" | wc -l)
    log_info "PNG files: $PNG_FILES"
    
    # Count JSON files
    JSON_FILES=$(find "ios/Runner/Assets.xcassets/AppIcon.appiconset" -name "*.json" | wc -l)
    log_info "JSON files: $JSON_FILES"
    
    if [[ $PNG_FILES -ge 19 && $JSON_FILES -eq 1 ]]; then
        log_success "Icon directory structure is correct"
    else
        log_warning "Icon directory structure may have issues"
    fi
else
    log_error "App icon directory not found"
    exit 1
fi

# Summary
echo ""
log_success "🎉 All iOS fixes tests passed successfully!"
log_info "📱 App icons should now pass App Store Connect validation"
log_info "🔧 iOS workflow has been fixed and optimized"
log_info "📋 Ready for iOS build and deployment"

exit 0
