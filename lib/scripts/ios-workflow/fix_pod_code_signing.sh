#!/bin/bash
# 🔧 Fix Pod Code Signing Issues
# Ensures all Pod targets use automatic code signing to prevent provisioning profile errors

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [POD_SIGNING] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

log_info "Starting Pod code signing fix..."

# Check if Pods project exists
PODS_PROJECT="ios/Pods/Pods.xcodeproj/project.pbxproj"
if [[ ! -f "$PODS_PROJECT" ]]; then
    log_error "Pods project not found at $PODS_PROJECT"
    log_info "Run 'pod install' first to generate the Pods project"
    exit 1
fi

log_info "Found Pods project, fixing code signing settings..."

# Create a backup of the original project file
cp "$PODS_PROJECT" "${PODS_PROJECT}.backup.$(date +%Y%m%d_%H%M%S)"
log_success "Created backup of Pods project"

# Fix code signing settings for all Pod targets
# Remove any provisioning profile specifications that cause errors
sed -i.bak '/PROVISIONING_PROFILE_SPECIFIER = ".*";/d' "$PODS_PROJECT"
sed -i.bak '/CODE_SIGN_STYLE = Manual;/d' "$PODS_PROJECT"
sed -i.bak '/DEVELOPMENT_TEAM = ".*";/d' "$PODS_PROJECT"
sed -i.bak '/CODE_SIGN_IDENTITY = ".*";/d' "$PODS_PROJECT"

# Clean up backup file
rm -f "${PODS_PROJECT}.bak" 2>/dev/null || true

log_success "✅ Removed problematic code signing settings from Pod targets"

# Verify the fix
if grep -q "PROVISIONING_PROFILE_SPECIFIER" "$PODS_PROJECT"; then
    log_warning "⚠️ Some PROVISIONING_PROFILE_SPECIFIER settings may still exist"
    grep "PROVISIONING_PROFILE_SPECIFIER" "$PODS_PROJECT" || true
else
    log_success "✅ All PROVISIONING_PROFILE_SPECIFIER settings removed"
fi

if grep -q "CODE_SIGN_STYLE = Manual" "$PODS_PROJECT"; then
    log_warning "⚠️ Some CODE_SIGN_STYLE = Manual settings may still exist"
    grep "CODE_SIGN_STYLE = Manual" "$PODS_PROJECT" || true
else
    log_success "✅ All CODE_SIGN_STYLE = Manual settings removed"
fi

log_success "🎉 Pod code signing fix completed successfully!"
log_info "📱 Pod targets will now use automatic code signing"
log_info "🔐 Main app target will still use manual signing with provisioning profile"
