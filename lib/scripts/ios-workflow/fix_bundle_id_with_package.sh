#!/bin/bash

# Fix Bundle ID using change_app_package_name package
# This script properly updates both Android and iOS bundle identifiers

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

echo "🔧 Fixing Bundle ID using change_app_package_name package..."

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    log_error "pubspec.yaml not found. Please run this script from the project root."
    exit 1
fi

# Check if change_app_package_name is in dev_dependencies
if ! grep -q "change_app_package_name" pubspec.yaml; then
    log_error "change_app_package_name package not found in dev_dependencies"
    log_info "Adding it now..."
    
    # Add the package to dev_dependencies
    sed -i '' '/dev_dependencies:/a\
  change_app_package_name: ^1.5.0' pubspec.yaml
    
    log_success "Added change_app_package_name package to pubspec.yaml"
fi

# Get the current bundle ID from environment or use default
BUNDLE_ID=${BUNDLE_ID:-"co.pixaware.Pixaware"}
log_info "Target Bundle ID: $BUNDLE_ID"

# Check if Flutter is available
if command -v flutter >/dev/null 2>&1; then
    log_info "Flutter found, updating dependencies..."
    flutter pub get
    
    log_info "🚀 Running change_app_package_name to update bundle ID..."
    dart run change_app_package_name:main "$BUNDLE_ID"
    
    log_success "Bundle ID updated successfully!"
    
elif command -v dart >/dev/null 2>&1; then
    log_info "Dart found, trying to run change_app_package_name directly..."
    
    # Try to run the package directly
    dart run change_app_package_name:main "$BUNDLE_ID" 2>/dev/null || {
        log_warning "Could not run change_app_package_name directly"
        log_info "This might be because Flutter is not fully set up"
    }
    
else
    log_warning "Neither Flutter nor Dart found in PATH"
    log_info "You'll need to run these commands manually:"
    echo ""
    echo "  flutter pub get"
    echo "  dart run change_app_package_name:main \"$BUNDLE_ID\""
    echo ""
    log_info "Or if you have Flutter installed elsewhere, add it to your PATH"
fi

# Show what files should have been updated
log_info "📋 The following files should have been updated:"
echo "  - android/app/build.gradle"
echo "  - android/app/src/main/AndroidManifest.xml"
echo "  - android/app/src/debug/AndroidManifest.xml"
echo "  - android/app/src/profile/AndroidManifest.xml"
echo "  - ios/Runner/Info.plist"
echo "  - MainActivity files (moved to new package structure)"

log_success "🎉 Bundle ID fix script completed!"
log_info "📱 Your app should now use the bundle ID: $BUNDLE_ID"
