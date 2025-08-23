#!/bin/bash

# Check and Fix Codemagic Rules Compliance
# This script ensures all workflows and scripts follow the codemagic-rules.mdc guidelines

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

echo "🔍 Checking Codemagic Rules Compliance..."

# List of forbidden hardcoded values from codemagic-rules.mdc
FORBIDDEN_VALUES=(
    "1.0.0"
    "com.example"
    "com.test.app"
    "QuikApp"
    "admin@example.com"
    "TEST123"
    "MyCoolApp"
)

# List of required environment variables
REQUIRED_ENV_VARS=(
    "PROJECT_ID"
    "APP_NAME"
    "VERSION_NAME"
    "VERSION_CODE"
    "WORKFLOW_ID"
    "BUNDLE_ID"
    "PKG_NAME"
    "EMAIL_ID"
    "APPLE_TEAM_ID"
)

# Check for hardcoded forbidden values
log_info "🔍 Checking for hardcoded forbidden values..."

VIOLATIONS_FOUND=0
for value in "${FORBIDDEN_VALUES[@]}"; do
    VIOLATIONS=$(grep -r "$value" lib/scripts/ codemagic.yaml 2>/dev/null | grep -v "check_codemagic_rules_compliance.sh" | wc -l || echo "0")
    if [ "$VIOLATIONS" -gt 0 ]; then
        log_warning "Found $VIOLATIONS instances of hardcoded value: $value"
        VIOLATIONS_FOUND=$((VIOLATIONS_FOUND + 1))
        
        # Show the files and lines where violations occur
        log_info "Files containing '$value':"
        grep -r "$value" lib/scripts/ codemagic.yaml 2>/dev/null | grep -v "check_codemagic_rules_compliance.sh" | head -5
    fi
done

# Check codemagic.yaml for proper environment variable usage
log_info "🔍 Checking codemagic.yaml for proper environment variable usage..."

# Check if any hardcoded values exist in codemagic.yaml
HARDCODED_IN_YAML=$(grep -v "^#" codemagic.yaml | grep -E "\"[a-zA-Z0-9._-]+\"" | grep -v "\$" | wc -l || echo "0")
if [ "$HARDCODED_IN_YAML" -gt 0 ]; then
    log_warning "Found $HARDCODED_IN_YAML potential hardcoded values in codemagic.yaml"
    log_info "Lines with potential hardcoded values:"
    grep -v "^#" codemagic.yaml | grep -E "\"[a-zA-Z0-9._-]+\"" | grep -v "\$" | head -5
    VIOLATIONS_FOUND=$((VIOLATIONS_FOUND + 1))
else
    log_success "codemagic.yaml appears to use environment variables properly"
fi

# Check for proper environment variable references
log_info "🔍 Checking for proper environment variable references..."

# Look for patterns like $VAR or ${VAR} in codemagic.yaml
ENV_VAR_REFERENCES=$(grep -c "\$[A-Z_]" codemagic.yaml || echo "0")
log_info "Found $ENV_VAR_REFERENCES environment variable references in codemagic.yaml"

# Check scripts for proper environment variable usage
log_info "🔍 Checking scripts for proper environment variable usage..."

SCRIPTS_WITH_HARDCODED=$(find lib/scripts/ -name "*.sh" -exec grep -l "1\.0\.0\|com\.example\|QuikApp" {} \; 2>/dev/null | wc -l || echo "0")
if [ "$SCRIPTS_WITH_HARDCODED" -gt 0 ]; then
    log_warning "Found $SCRIPTS_WITH_HARDCODED scripts with potential hardcoded values"
    VIOLATIONS_FOUND=$((VIOLATIONS_FOUND + 1))
else
    log_success "All scripts appear to use environment variables properly"
fi

# Summary
echo ""
if [ "$VIOLATIONS_FOUND" -eq 0 ]; then
    log_success "🎉 All Codemagic rules compliance checks passed!"
    log_info "✅ No hardcoded forbidden values found"
    log_info "✅ codemagic.yaml uses environment variables properly"
    log_info "✅ Scripts use environment variables properly"
else
    log_warning "⚠️ Found $VIOLATIONS_FOUND compliance violations"
    log_info "🔧 Please review and fix the issues above"
    log_info "📋 Remember: All values must come from environment variables, not hardcoded literals"
fi

echo ""
log_info "📋 Codemagic Rules Summary:"
echo "  ❌ Do NOT hardcode: PROJECT_ID, APP_NAME, VERSION_NAME, VERSION_CODE, etc."
echo "  ✅ Use environment variables: \$VAR or \${VAR}"
echo "  🔧 Scripts must read from environment variables or external config files"
echo "  🚫 Never write secrets or environment-specific config directly in code"
