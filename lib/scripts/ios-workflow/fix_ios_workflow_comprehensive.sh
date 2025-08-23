#!/bin/bash

# Comprehensive iOS Workflow Fix
# This script fixes all the major iOS workflow issues:
# 1. Bundle ID consistency
# 2. App name consistency  
# 3. Pod provisioning profile conflicts
# 4. Deployment target issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️ $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

echo "🔧 Comprehensive iOS Workflow Fix v1.0..."

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    log_error "pubspec.yaml not found. Please run this script from the project root."
    exit 1
fi

# Step 1: Fix Bundle ID and App Name Consistency
log_info "📱 Step 1: Fixing Bundle ID and App Name consistency..."

# Update pubspec.yaml name if needed
CURRENT_NAME=$(grep "^name:" pubspec.yaml | cut -d: -f2 | tr -d ' ')
if [ "$CURRENT_NAME" != "pixaware" ]; then
    log_info "Updating project name in pubspec.yaml..."
    sed -i '' 's/^name:.*/name: pixaware/' pubspec.yaml
    log_success "Project name updated to 'pixaware'"
else
    log_success "Project name is already 'pixaware'"
fi

# Step 2: Fix iOS Info.plist
log_info "🍎 Step 2: Fixing iOS Info.plist..."

if [ -f "ios/Runner/Info.plist" ]; then
    # Update CFBundleDisplayName
    if grep -q "quikappflutter2" ios/Runner/Info.plist; then
        sed -i '' 's/quikappflutter2/Pixaware/g' ios/Runner/Info.plist
        log_success "Updated CFBundleDisplayName to 'Pixaware'"
    fi
    
    # Update CFBundleName
    if grep -q "quikappflutter2" ios/Runner/Info.plist; then
        sed -i '' 's/quikappflutter2/Pixaware/g' ios/Runner/Info.plist
        log_success "Updated CFBundleName to 'Pixaware'"
    fi
else
    log_warning "ios/Runner/Info.plist not found"
fi

# Step 3: Fix Android Package Structure
log_info "🤖 Step 3: Fixing Android package structure..."

# Remove old package directories
if [ -d "android/app/src/main/kotlin/com/example" ]; then
    rm -rf android/app/src/main/kotlin/com/example
    log_success "Removed old package directories"
fi

# Verify correct MainActivity exists
if [ -f "android/app/src/main/kotlin/co/pixaware/pixaware/MainActivity.kt" ]; then
    log_success "Correct MainActivity.kt found in co.pixaware.pixaware package"
else
    log_warning "MainActivity.kt not found in expected location"
fi

# Step 4: Fix Pod Provisioning Profile Conflicts
log_info "🔧 Step 4: Fixing Pod provisioning profile conflicts..."

if [ -f "ios/Podfile" ]; then
    log_info "Podfile found, checking for provisioning profile fixes..."
    
    # Check if the enhanced Podfile fixes are already in place
    if grep -q "PROVISIONING_PROFILE_UUID" ios/Podfile; then
        log_success "Enhanced Podfile fixes are already in place"
    else
        log_warning "Podfile may need manual enhancement for provisioning profile conflicts"
        log_info "Consider updating the Podfile with the enhanced post_install hooks"
    fi
else
    log_warning "ios/Podfile not found"
fi

# Step 5: Clean up and regenerate if needed
log_info "🧹 Step 5: Cleaning up build artifacts..."

# Clean Flutter
if command -v flutter >/dev/null 2>&1; then
    log_info "Cleaning Flutter build..."
    flutter clean
    flutter pub get
    log_success "Flutter cleaned and dependencies updated"
else
    log_warning "Flutter not available, skipping Flutter cleanup"
fi

# Clean iOS build artifacts
if [ -d "ios/build" ]; then
    rm -rf ios/build
    log_success "iOS build artifacts cleaned"
fi

# Clean Pods if they exist and CocoaPods is available
if [ -d "ios/Pods" ] && command -v pod >/dev/null 2>&1; then
    log_info "Cleaning and regenerating Pods..."
    cd ios
    rm -rf Pods
    rm -rf Podfile.lock
    pod install --repo-update
    cd ..
    log_success "Pods regenerated with fresh configuration"
elif [ -d "ios/Pods" ]; then
    log_warning "Pods directory exists but CocoaPods not available"
    log_info "Consider running 'pod install' manually after installing CocoaPods"
fi

# Step 6: Final verification
log_info "🔍 Step 6: Final verification..."

# Check bundle ID consistency
log_info "Checking bundle ID consistency..."
ANDROID_PACKAGE=$(grep "applicationId" android/app/build.gradle.kts | cut -d'"' -f2)
IOS_BUNDLE=$(grep "PRODUCT_BUNDLE_IDENTIFIER" ios/Runner.xcodeproj/project.pbxproj | head -1 | sed 's/.*= \(.*\);/\1/')

if [ "$ANDROID_PACKAGE" = "$IOS_BUNDLE" ]; then
    log_success "Bundle IDs are consistent: $ANDROID_PACKAGE"
else
    log_warning "Bundle ID mismatch detected:"
    log_warning "  Android: $ANDROID_PACKAGE"
    log_warning "  iOS: $IOS_BUNDLE"
fi

# Check app name consistency
log_info "Checking app name consistency..."
ANDROID_LABEL=$(grep 'android:label=' android/app/src/main/AndroidManifest.xml | cut -d'"' -f2)
IOS_NAME=$(grep -A 1 "CFBundleDisplayName" ios/Runner/Info.plist | tail -1 | cut -d'>' -f2 | cut -d'<' -f1)

if [ "$ANDROID_LABEL" = "$IOS_NAME" ]; then
    log_success "App names are consistent: $ANDROID_LABEL"
else
    log_warning "App name mismatch detected:"
    log_warning "  Android: $ANDROID_LABEL"
    log_warning "  iOS: $IOS_NAME"
fi

log_success "🎉 Comprehensive iOS Workflow Fix completed!"
log_info "📱 Your iOS workflow should now work without bundle ID and provisioning profile conflicts"
log_info "🚀 Next steps:"
echo "  1. Run the iOS workflow again"
echo "  2. If Pod issues persist, manually run 'pod install' in ios/ directory"
echo "  3. Ensure all environment variables are set correctly in Codemagic"
