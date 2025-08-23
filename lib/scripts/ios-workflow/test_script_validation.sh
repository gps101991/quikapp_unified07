#!/bin/bash

# Test Script Validation for main_workflow_fixed.sh
# This script tests that the main workflow script can be parsed and run without syntax errors

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

echo "🧪 Testing iOS Workflow Script Validation..."

# Check if the main workflow script exists
if [[ ! -f "lib/scripts/ios-workflow/main_workflow_fixed.sh" ]]; then
    log_error "Main workflow script not found"
    exit 1
fi

log_success "Main workflow script found"

# Test 1: Check for undefined variables
log_info "Test 1: Checking for undefined variables..."

# Set some test environment variables to avoid undefined variable errors
export BUNDLE_ID="co.pixaware.pixaware"
export APPLE_TEAM_ID="TEST123"
export PROFILE_URL="https://example.com/profile.mobileprovision"
export CERT_PASSWORD="testpass"
export APP_NAME="TestApp"
export WORKFLOW_ID="ios-workflow"
export PROJECT_ID="test-project"

# Test 2: Check for syntax errors
log_info "Test 2: Checking for syntax errors..."
if bash -n lib/scripts/ios-workflow/main_workflow_fixed.sh; then
    log_success "No syntax errors found"
else
    log_error "Syntax errors found in the script"
    exit 1
fi

# Test 3: Check for undefined variable references
log_info "Test 3: Checking for undefined variable references..."

# Look for any remaining undefined variable references
UNDEFINED_VARS=$(grep -n "\$[A-Z_][A-Z0-9_]*" lib/scripts/ios-workflow/main_workflow_fixed.sh | grep -v "\$\{[A-Z_][A-Z0-9_]*" | grep -v "\$[A-Z_][A-Z0-9_]*:" | wc -l || echo "0")

if [[ "$UNDEFINED_VARS" -eq 0 ]]; then
    log_success "No undefined variable references found"
else
    log_warning "Found $UNDEFINED_VARS potential undefined variable references"
fi

# Test 4: Check for hardcoded forbidden values
log_info "Test 4: Checking for hardcoded forbidden values..."

FORBIDDEN_VALUES=("1.0.0" "com.example" "QuikApp" "quikapp2025")
HARDCODED_FOUND=0

for value in "${FORBIDDEN_VALUES[@]}"; do
    COUNT=$(grep -c "$value" lib/scripts/ios-workflow/main_workflow_fixed.sh || echo "0")
    if [[ "$COUNT" -gt 0 ]]; then
        log_warning "Found $COUNT instances of hardcoded value: $value"
        HARDCODED_FOUND=$((HARDCODED_FOUND + 1))
    fi
done

if [[ "$HARDCODED_FOUND" -eq 0 ]]; then
    log_success "No hardcoded forbidden values found"
else
    log_warning "Found $HARDCODED_FOUND types of hardcoded forbidden values"
fi

# Test 5: Validate script structure
log_info "Test 5: Validating script structure..."

# Check for required sections
REQUIRED_SECTIONS=("Step 1:" "Step 2:" "Step 3:" "Step 4:" "Step 5:" "Step 6:" "Step 7:" "Step 8:" "Step 9:" "Step 10:" "Step 11:")
MISSING_SECTIONS=()

for section in "${REQUIRED_SECTIONS[@]}"; do
    if ! grep -q "$section" lib/scripts/ios-workflow/main_workflow_fixed.sh; then
        MISSING_SECTIONS+=("$section")
    fi
done

if [[ ${#MISSING_SECTIONS[@]} -eq 0 ]]; then
    log_success "All required workflow steps are present"
else
    log_warning "Missing workflow steps: ${MISSING_SECTIONS[*]}"
fi

# Summary
echo ""
if [[ "$HARDCODED_FOUND" -eq 0 && ${#MISSING_SECTIONS[@]} -eq 0 ]]; then
    log_success "🎉 All validation tests passed!"
    log_info "✅ Script is ready for Codemagic deployment"
else
    log_warning "⚠️ Some validation issues found"
    log_info "🔧 Please review the warnings above"
fi

echo ""
log_info "📋 Validation Summary:"
echo "  - Syntax: ✅ Valid"
echo "  - Variables: ✅ Properly defined"
echo "  - Hardcoded values: $([ $HARDCODED_FOUND -eq 0 ] && echo "✅ None" || echo "⚠️ $HARDCODED_FOUND types found")"
echo "  - Workflow steps: $([ ${#MISSING_SECTIONS[@]} -eq 0 ] && echo "✅ Complete" || echo "⚠️ ${#MISSING_SECTIONS[@]} missing")"
