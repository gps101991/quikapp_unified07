#!/bin/bash

# Fix Pod Provisioning Profile Conflicts
# This script resolves the common issue where Pod targets try to use provisioning profiles

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

echo "🔧 Fixing Pod Provisioning Profile Conflicts..."

# Check if we're in the right directory
if [ ! -f "ios/Podfile" ]; then
    log_error "Podfile not found. Please run this script from the project root."
    exit 1
fi

cd ios

log_info "🧹 Cleaning up existing Pods..."
rm -rf Pods
rm -rf Podfile.lock
rm -rf .symlinks

log_info "🔧 Regenerating Pods with fixed settings..."
pod install --repo-update

log_info "🔍 Verifying Pod configuration..."
if [ -d "Pods" ]; then
    log_success "Pods regenerated successfully"
    
    # Check if there are any remaining provisioning profile references
    log_info "🔍 Checking for remaining provisioning profile references..."
    
    # Look for any remaining provisioning profile settings in Pods
    PROFILE_REFS=$(find Pods -name "*.pbxproj" -exec grep -l "PROVISIONING_PROFILE" {} \; 2>/dev/null || true)
    
    if [ -n "$PROFILE_REFS" ]; then
        log_warning "Found Pod targets with provisioning profile references:"
        echo "$PROFILE_REFS"
        log_info "These should be automatically resolved by the Podfile post_install hook"
    else
        log_success "No provisioning profile references found in Pods"
    fi
    
    # Check deployment targets
    log_info "🔍 Checking Pod deployment targets..."
    DEPLOYMENT_TARGETS=$(find Pods -name "*.pbxproj" -exec grep -h "IPHONEOS_DEPLOYMENT_TARGET" {} \; 2>/dev/null | sort | uniq || true)
    
    if [ -n "$DEPLOYMENT_TARGETS" ]; then
        log_info "Current Pod deployment targets:"
        echo "$DEPLOYMENT_TARGETS"
    fi
    
else
    log_error "Failed to regenerate Pods"
    exit 1
fi

log_success "🎉 Pod provisioning profile conflicts should now be resolved!"
log_info "📱 You can now run the iOS workflow again"

cd ..
