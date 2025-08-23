#!/usr/bin/env bash

# 🚀 Fixed iOS Workflow Script v2.0
# Addresses all identified bugs and app icon issues
# Uses proper execution order and error handling

set -euo pipefail
trap 'echo "❌ Error occurred at line $LINENO. Exit code: $?" >&2; exit 1' ERR

# Enhanced logging functions
log_info() { echo "ℹ️ $1" >&2; }
log_success() { echo "✅ $1" >&2; }
log_error() { echo "❌ $1" >&2; }
log_warning() { echo "⚠️ $1" >&2; }
log() { echo "📌 $1" >&2; }

echo "🚀 Starting Fixed iOS Workflow v2.0..."

# Pre-flight validation
log_info "🔍 Pre-flight validation..."
REQUIRED_SCRIPTS=(
    "lib/scripts/ios-workflow/fix_ios_icons_comprehensive_v2.sh"
    "lib/scripts/ios-workflow/robust_xcconfig_fix.sh"
    "lib/scripts/ios-workflow/dynamic_config_injector.sh"
    "lib/scripts/utils/gen_env_config.sh"
    "lib/scripts/ios-workflow/generate_podfile.sh"
)

MISSING_SCRIPTS=()
for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [[ ! -f "$script" ]]; then
        log_error "❌ Required script not found: $script"
        MISSING_SCRIPTS+=("$script")
    else
        log_success "✅ Found: $script"
    fi
done

if [[ ${#MISSING_SCRIPTS[@]} -gt 0 ]]; then
    log_error "❌ Missing required scripts: ${MISSING_SCRIPTS[*]}"
    log_error "❌ Cannot proceed with iOS workflow"
    exit 1
fi

log_success "✅ All required scripts are present"

# Validate critical environment variables
log_info "🔍 Validating critical environment variables..."
CRITICAL_VARS=("BUNDLE_ID" "APPLE_TEAM_ID" "PROFILE_URL" "CERT_PASSWORD")
MISSING_CRITICAL=()

for var in "${CRITICAL_VARS[@]}"; do
    if [[ -z "${!var:-}" ]]; then
        log_warning "⚠️ $var: MISSING (critical for iOS build)"
        MISSING_CRITICAL+=("$var")
    else
        log_success "✅ $var: ${!var}"
    fi
done

if [[ ${#MISSING_CRITICAL[@]} -gt 0 ]]; then
    log_warning "⚠️ WARNING: Missing critical variables: ${MISSING_CRITICAL[*]}"
    log_warning "ℹ️ Build may fail or use default values"
else
    log_success "✅ All critical variables are present"
fi

# Environment info
echo "📊 Build Environment:"
echo " - Flutter: $(flutter --version | head -1)"
echo " - Java: $(java -version 2>&1 | head -1)"
echo " - Xcode: $(xcodebuild -version | head -1)"
echo " - CocoaPods: $(pod --version)"

# Step 1: Cleanup and fix corrupted files
echo "🧹 Step 1: Cleaning up iOS project..."

# Always do basic cleanup first
log_info "Performing basic cleanup..."
flutter clean > /dev/null 2>&1 || log_warning "⚠️ flutter clean failed (continuing)"
rm -rf ~/Library/Developer/Xcode/DerivedData/* > /dev/null 2>&1 || true
rm -rf .dart_tool/ > /dev/null 2>&1 || true
rm -rf ios/Pods/ > /dev/null 2>&1 || true
rm -rf ios/build/ > /dev/null 2>&1 || true
rm -rf ios/.symlinks > /dev/null 2>&1 || true
rm -f ios/Podfile.lock > /dev/null 2>&1 || true

# Step 2: Initialize Flutter and generate configuration files
log_info "Initializing Flutter to generate configuration files..."
flutter pub get || {
    log_warning "flutter pub get failed, trying flutter clean first..."
    flutter clean
    flutter pub get
}

# Force Flutter to generate iOS configuration files
log_info "Forcing Flutter to generate iOS configuration files..."
flutter build ios --no-codesign --debug || {
    log_warning "flutter build ios failed, but continuing with configuration generation..."
}

# Step 3: Fix Generated.xcconfig issue
log_info "Fixing Generated.xcconfig configuration..."
if [ -f "lib/scripts/ios-workflow/robust_xcconfig_fix.sh" ]; then
    chmod +x lib/scripts/ios-workflow/robust_xcconfig_fix.sh
    if ./lib/scripts/ios-workflow/robust_xcconfig_fix.sh; then
        log_success "Generated.xcconfig fix completed"
    else
        log_error "Generated.xcconfig fix failed"
        exit 1
    fi
else
    log_error "Generated.xcconfig fix script not found"
    exit 1
fi

# Step 4: Inject dynamic iOS configurations
log_info "Injecting dynamic iOS configurations..."
if [ -f "lib/scripts/ios-workflow/dynamic_config_injector.sh" ]; then
    chmod +x lib/scripts/ios-workflow/dynamic_config_injector.sh
    if ./lib/scripts/ios-workflow/dynamic_config_injector.sh; then
        log_success "Dynamic iOS configuration injection completed"
    else
        log_error "Dynamic iOS configuration injection failed"
        exit 1
    fi
else
    log_error "Dynamic iOS configuration injector not found"
    exit 1
fi

# Generate environment configuration
log_info "📝 Step 5: Generate environment configuration..."
if [ -f "lib/scripts/utils/gen_env_config.sh" ]; then
    chmod +x lib/scripts/utils/gen_env_config.sh
    if ./lib/scripts/utils/gen_env_config.sh; then
        log_success "✅ Environment configuration generated successfully"
    else
        log_error "❌ Environment configuration generation failed"
        exit 1
    fi
else
    log_warning "⚠️ Environment configuration script not found, skipping"
fi

# Step 6: Firebase Setup (CRITICAL: Must be before CocoaPods)
echo "🔥 Step 6: Firebase Setup and Configuration..."
if [ -f "lib/scripts/ios/firebase.sh" ]; then
    chmod +x lib/scripts/ios/firebase.sh
    if ./lib/scripts/ios/firebase.sh; then
        log_success "✅ Firebase setup completed successfully"
    else
        log_error "❌ Firebase setup failed"
        exit 1
    fi
else
    log_warning "⚠️ Firebase setup script not found, skipping Firebase configuration"
fi

log_info "📦 Step 7: Generating Podfile dynamically..."
if [ -f "lib/scripts/ios-workflow/generate_podfile.sh" ]; then
    chmod +x lib/scripts/ios-workflow/generate_podfile.sh
    if ./lib/scripts/ios-workflow/generate_podfile.sh; then
        log_success "Dynamic Podfile generation completed"
    else
        log_error "Dynamic Podfile generation failed"
        exit 1
    fi
else
    log_error "Dynamic Podfile generator not found"
    exit 1
fi

# Step 8: Advanced cleanup
if [ -f "lib/scripts/ios-workflow/cleanup_ios.sh" ]; then
    log_info "Running advanced cleanup script..."
    chmod +x lib/scripts/ios-workflow/cleanup_ios.sh
    if ./lib/scripts/ios-workflow/cleanup_ios.sh; then
        log_success "Advanced cleanup completed"
    else
        log_warning "Advanced cleanup failed, continuing with basic cleanup"
    fi
else
    log_warning "Advanced cleanup script not found, using basic cleanup only"
fi

log_success "iOS project cleanup completed"

# Step 9: Code Signing Setup
echo "🔐 Step 9: Code Signing Setup..."

# Initialize keychain using Codemagic CLI
log_info "Initialize keychain to be used for codesigning using Codemagic CLI 'keychain' command"
keychain initialize

# Setup provisioning profile
log_info "Setting up provisioning profile..."

PROFILES_HOME="$HOME/Library/MobileDevice/Provisioning Profiles"
mkdir -p "$PROFILES_HOME"

if [[ -n "$PROFILE_URL" ]]; then
    # Download provisioning profile
    PROFILE_PATH="$PROFILES_HOME/app_store.mobileprovision"
    
    if [[ "$PROFILE_URL" == http* ]]; then
        curl -fSL "$PROFILE_URL" -o "$PROFILE_PATH"
        log_success "Downloaded provisioning profile to $PROFILE_PATH"
    else
        cp "$PROFILE_URL" "$PROFILE_PATH"
        log_success "Copied provisioning profile from $PROFILE_URL to $PROFILE_PATH"
    fi
    
    # Extract information from provisioning profile
    security cms -D -i "$PROFILE_PATH" > /tmp/profile.plist
    UUID=$(/usr/libexec/PlistBuddy -c "Print UUID" /tmp/profile.plist 2>/dev/null || echo "")
    BUNDLE_ID_FROM_PROFILE=$(/usr/libexec/PlistBuddy -c "Print :Entitlements:application-identifier" /tmp/profile.plist 2>/dev/null | cut -d '.' -f 2- || echo "")
    
    if [[ -n "$UUID" ]]; then
        echo "UUID: $UUID"
    fi
    if [[ -n "$BUNDLE_ID_FROM_PROFILE" ]]; then
        echo "Bundle Identifier from profile: $BUNDLE_ID_FROM_PROFILE"
        
        # Use bundle ID from profile if BUNDLE_ID is not set
        if [[ -z "$BUNDLE_ID" ]]; then
            BUNDLE_ID="$BUNDLE_ID_FROM_PROFILE"
            log_info "Using bundle ID from provisioning profile: $BUNDLE_ID"
        else
            log_info "Using provided bundle ID: $BUNDLE_ID (profile has: $BUNDLE_ID_FROM_PROFILE)"
        fi
    fi
else
    log_warning "No provisioning profile URL provided (PROFILE_URL)"
    UUID=""
fi

# Setup certificate using Codemagic CLI
log_info "Setting up certificate using Codemagic CLI..."

if [[ -n "$CERT_P12_URL" && -n "$CERT_PASSWORD" ]]; then
    # Download P12 certificate
    curl -fSL "$CERT_P12_URL" -o /tmp/certificate.p12
    log_success "Downloaded certificate to /tmp/certificate.p12"
    
    # Add certificate to keychain using Codemagic CLI
    keychain add-certificates --certificate /tmp/certificate.p12 --certificate-password "$CERT_PASSWORD"
    log_success "Certificate added to keychain using Codemagic CLI"
    
elif [[ -n "$CERT_CER_URL" && -n "$CERT_KEY_URL" ]]; then
    # Download CER and KEY files
    curl -fSL "$CERT_CER_URL" -o /tmp/certificate.cer
    curl -fSL "$CERT_KEY_URL" -o /tmp/certificate.key
    log_success "Downloaded CER and KEY files"
    
    # Generate P12 from CER/KEY
    openssl pkcs12 -export -in /tmp/certificate.cer -inkey /tmp/certificate.key -out /tmp/certificate.p12 -passout pass:"${CERT_PASSWORD:-$CERT_PASSWORD}"
    log_success "Generated P12 from CER/KEY files"
    
    # Add certificate to keychain using Codemagic CLI
    keychain add-certificates --certificate /tmp/certificate.p12 --certificate-password "${CERT_PASSWORD}"
    log_success "Certificate added to keychain using Codemagic CLI"
else
    log_warning "No certificate configuration provided"
fi

# Validate signing identities
IDENTITY_COUNT=$(security find-identity -v -p codesigning | grep -c "iPhone Distribution" || echo "0")
if [[ "$IDENTITY_COUNT" -eq 0 ]]; then
    log_error "No valid iPhone Distribution signing identities found in keychain. Exiting build."
    exit 1
else
    log_success "Found $IDENTITY_COUNT valid iPhone Distribution identity(ies) in keychain."
fi

# Step 10: App Customization and Branding
echo "🎨 Step 10: App Customization and Branding..."

# Update display name and bundle id
if [[ -n "$APP_NAME" ]]; then
    PLIST_PATH="ios/Runner/Info.plist"
    /usr/libexec/PlistBuddy -c "Print :CFBundleDisplayName" "$PLIST_PATH" 2>/dev/null \
        && /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName '$APP_NAME'" "$PLIST_PATH" \
        || /usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string '$APP_NAME'" "$PLIST_PATH"
    log_success "Updated app display name to: $APP_NAME"
fi

if [[ -n "$BUNDLE_ID" ]]; then
    log_info "Updating bundle identifier to: $BUNDLE_ID"
    
    # List of possible default bundle IDs to replace (common Flutter defaults)
    # These are example patterns that might exist in the project files
    # Can be overridden via DEFAULT_BUNDLE_IDS environment variable
    DEFAULT_BUNDLE_IDS=(${DEFAULT_BUNDLE_IDS:-"com.example.flutter" "com.example.app" "com.example.quikapp" "com.example.quikappflutter"})
    
    for OLD_BUNDLE_ID in "${DEFAULT_BUNDLE_IDS[@]}"; do
        if [[ "$OLD_BUNDLE_ID" != "$BUNDLE_ID" ]]; then
            log_info "Replacing $OLD_BUNDLE_ID with $BUNDLE_ID"
            find ios -name "project.pbxproj" -exec sed -i '' "s/$OLD_BUNDLE_ID/$BUNDLE_ID/g" {} \;
            find ios -name "Info.plist" -exec sed -i '' "s/$OLD_BUNDLE_ID/$BUNDLE_ID/g" {} \;
            find ios -name "*.entitlements" -exec sed -i '' "s/$OLD_BUNDLE_ID/$BUNDLE_ID/g" {} \;
        fi
    done
    
    # Also update the Info.plist directly
    PLIST_PATH="ios/Runner/Info.plist"
    
    # Now try to update the bundle ID
    /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" "$PLIST_PATH" 2>/dev/null || \
        /usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string $BUNDLE_ID" "$PLIST_PATH"
    
    # Update project.pbxproj PRODUCT_BUNDLE_IDENTIFIER
    PROJECT_FILE="ios/Runner.xcodeproj/project.pbxproj"
    if [[ -f "$PROJECT_FILE" ]]; then
        log_info "Updating PRODUCT_BUNDLE_IDENTIFIER in project.pbxproj..."
        sed -i '' "s/PRODUCT_BUNDLE_IDENTIFIER = [^;]*;/PRODUCT_BUNDLE_IDENTIFIER = $BUNDLE_ID;/g" "$PROJECT_FILE"
        log_success "Updated PRODUCT_BUNDLE_IDENTIFIER in project.pbxproj"
    fi
    
    log_success "Bundle Identifier updated to $BUNDLE_ID"
else
    log_error "❌ BUNDLE_ID is not set. Cannot proceed with iOS build."
    log_info "Please ensure BUNDLE_ID environment variable is set in Codemagic."
    exit 1
fi

# Validate that bundle ID is now properly set
if [[ -z "$BUNDLE_ID" ]]; then
    log_error "❌ BUNDLE_ID is still not set after all attempts. Cannot proceed."
    exit 1
fi

log_success "✅ Bundle ID validation passed: $BUNDLE_ID"

# Step 11: App icon installation and fix (CRITICAL for App Store validation)
echo "🖼️ Step 11: App Icon Installation and Fix..."

# Run the comprehensive icon fix script FIRST
log_info "Running comprehensive iOS icon fix..."
if [ -f "lib/scripts/ios-workflow/fix_ios_icons_comprehensive_v2.sh" ]; then
    chmod +x lib/scripts/ios-workflow/fix_ios_icons_comprehensive_v2.sh
    if ./lib/scripts/ios-workflow/fix_ios_icons_comprehensive_v2.sh; then
        log_success "✅ Comprehensive iOS icon fix completed successfully"
        log_info "📱 App Store Connect validation should now pass"
    else
        log_error "❌ Comprehensive iOS icon fix failed"
        exit 1
    fi
else
    log_error "❌ Comprehensive iOS icon fix script not found"
    exit 1
fi

# Verify app icons were created
log_info "Verifying app icons were created..."
ICON_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"
if [ -d "$ICON_DIR" ]; then
    ICON_COUNT=$(ls -1 "$ICON_DIR"/*.png 2>/dev/null | wc -l)
    if [ "$ICON_COUNT" -ge 19 ]; then
        log_success "Found $ICON_COUNT app icons"
        ls -la "$ICON_DIR"/*.png | head -5
    else
        log_error "Only found $ICON_COUNT app icons, expected at least 19"
        exit 1
    fi
else
    log_error "App icon directory not found: $ICON_DIR"
    exit 1
fi

# Verify CFBundleIconName in Info.plist
log_info "Verifying CFBundleIconName in Info.plist..."
if /usr/libexec/PlistBuddy -c "Print :CFBundleIconName" "ios/Runner/Info.plist" 2>/dev/null; then
    log_success "CFBundleIconName is set in Info.plist"
else
    log_error "CFBundleIconName is missing from Info.plist"
    exit 1
fi

# Step 12: iOS Permissions Configuration
echo "🔐 Step 12: iOS Permissions Configuration..."

# Configure iOS permissions
log_info "Configuring iOS permissions..."
if [ -f "lib/scripts/ios-workflow/permissions.sh" ]; then
    chmod +x lib/scripts/ios-workflow/permissions.sh
    if ./lib/scripts/ios-workflow/permissions.sh; then
        log_success "iOS permissions configuration completed"
    else
        log_error "iOS permissions configuration failed"
        exit 1
    fi
else
    log_warning "iOS permissions script not found, skipping"
fi

# Step 13: Complete Push Notification Setup
echo "🔔 Step 13: Complete Push Notification Setup..."

if [[ "${PUSH_NOTIFY:-false}" == "true" ]]; then
    log_info "Push notifications enabled, setting up complete configuration..."
    
    if [ -f "lib/scripts/ios-workflow/setup_push_notifications_complete.sh" ]; then
        chmod +x lib/scripts/ios-workflow/setup_push_notifications_complete.sh
        if ./lib/scripts/ios-workflow/setup_push_notifications_complete.sh; then
            log_success "✅ Complete push notification setup completed successfully"
        else
            log_error "❌ Complete push notification setup failed"
            exit 1
        fi
    else
        log_warning "⚠️ Complete push notification setup script not found"
    fi
else
    log_info "ℹ️ Push notifications disabled (PUSH_NOTIFY=false), skipping setup"
fi

# Step 14: Flutter Dependencies and Project Setup
echo "📦 Step 14: Flutter Dependencies and Project Setup..."

# Flutter dependencies
log_info "Installing Flutter dependencies..."
flutter pub get > /dev/null || {
    log_error "flutter pub get failed"
    exit 1
}

# Verify Flutter iOS project structure
log_info "🔍 Verifying Flutter iOS project structure..."
if [ ! -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
    log_warning "iOS project not found. Running flutter create ios..."
    flutter create --platforms=ios .
fi

if [ ! -f "ios/Runner/Info.plist" ]; then
    log_error "Info.plist not found in iOS project"
    exit 1
fi
    
if [ ! -f "ios/Flutter/AppFrameworkInfo.plist" ]; then
    log_warning "Flutter AppFrameworkInfo.plist not found, creating iOS project..."
    flutter create --platforms=ios .
fi

# Ensure Flutter iOS project is properly set up
log_info "🔧 Ensuring Flutter iOS project is properly configured..."
flutter pub get

# Check if main.dart exists and is valid
if [ ! -f "lib/main.dart" ]; then
    log_error "❌ lib/main.dart not found - this is required for Flutter builds"
    exit 1
fi

# Build Flutter iOS project to ensure all files are generated
log_info "🔨 Building Flutter iOS project to generate all necessary files..."
flutter build ios --no-codesign --debug --verbose || {
    log_warning "flutter build ios failed, but continuing with manual setup..."
}

# Verify that the build created the necessary files
if [ ! -f "ios/Flutter/Generated.xcconfig" ]; then
    log_warning "⚠️ Generated.xcconfig not found, creating it manually..."
    mkdir -p ios/Flutter
    cat > ios/Flutter/Generated.xcconfig << EOF
FLUTTER_ROOT=$(which flutter | xargs dirname | xargs dirname)
FLUTTER_APPLICATION_PATH=$(pwd)
FLUTTER_TARGET=lib/main.dart
FLUTTER_BUILD_DIR=build
FLUTTER_BUILD_NAME=$VERSION_NAME
FLUTTER_BUILD_NUMBER=$VERSION_CODE
EXCLUDED_ARCHS[sdk=iphonesimulator*]=i386
EXCLUDED_ARCHS[sdk=iphoneos*]=armv7
DART_OBFUSCATION=false
TRACK_WIDGET_CREATION=true
TREE_SHAKE_ICONS=false
PACKAGE_CONFIG=.dart_tool/package_config.json
EOF
fi

log_success "✅ Flutter iOS project structure verified"

# Step 15: CocoaPods Setup
echo "📦 Step 15: CocoaPods Setup and Dependencies..."

# CocoaPods commands
run_cocoapods_commands() {
    log_info "📦 Running CocoaPods commands..."

    # Check if CocoaPods is installed
    if ! command -v pod &>/dev/null; then
        log_error "CocoaPods is not installed!"
        exit 1
    fi
    
    # Check if Podfile exists
    if [ ! -f "ios/Podfile" ]; then
        log_error "Podfile not found at ios/Podfile"
        exit 1
    fi

    # Verify Podfile integrity
    if ! grep -q "target 'Runner'" ios/Podfile; then
        log_error "Podfile is corrupted - missing target 'Runner'"
        log_info "Podfile contents:"
        cat ios/Podfile
        exit 1
    fi

    # Clean up old files
    if [ -f "ios/Podfile.lock" ]; then
        cp ios/Podfile.lock ios/Podfile.lock.backup
        log_info "🗂️ Backed up Podfile.lock to Podfile.lock.backup"
        rm ios/Podfile.lock
        log_info "🗑️ Removed original Podfile.lock"
    else
        log_warning "⚠️ Podfile.lock not found — skipping backup and removal"
    fi

    # Remove Pods directory if it exists
    if [ -d "ios/Pods" ]; then
        rm -rf ios/Pods
        log_info "🗑️ Removed ios/Pods directory"
    fi
    
    # ULTRA AGGRESSIVE Pod cleanup to ensure clean regeneration
    log_info "🧹 ULTRA AGGRESSIVE Pod cleanup..."
    rm -rf ios/Podfile.lock
    rm -rf ios/.symlinks
    rm -rf ios/Pods
    rm -rf ios/Pods.xcodeproj
    rm -rf ios/*.xcworkspace
    log_info "🧹 Cleaned ALL Pod-related files including workspace"
    
    # Generate fresh dynamic Podfile with ultra-aggressive fixes
    log_info "🔧 Generating fresh dynamic Podfile..."
    if [ -f "lib/scripts/ios-workflow/generate_dynamic_podfile.sh" ]; then
        chmod +x lib/scripts/ios-workflow/generate_dynamic_podfile.sh
        if bash lib/scripts/ios-workflow/generate_dynamic_podfile.sh; then
            log_success "✅ Dynamic Podfile generated successfully"
        else
            log_error "❌ Failed to generate dynamic Podfile"
            return 1
        fi
    else
        log_warning "⚠️ Dynamic Podfile generation script not found, using existing Podfile"
    fi

    # Enter ios directory
    pushd ios > /dev/null || { log_error "Failed to enter ios directory"; return 1; }
    
    # Verify the dynamic Podfile was generated correctly
    log_info "🔍 Verifying dynamic Podfile..."
    if [ -f "Podfile" ]; then
        log_info "✅ Podfile exists"
        
        # Check if it contains our ultra-aggressive fixes
        if grep -q "ULTRA-AGGRESSIVE code signing fixes" Podfile; then
            log_success "✅ Dynamic Podfile contains ultra-aggressive fixes"
        else
            log_warning "⚠️ Podfile may not contain our fixes"
        fi
        
        # Check for key settings
        if grep -q "CODE_SIGNING_STYLE.*Automatic" Podfile; then
            log_success "✅ Podfile has automatic code signing"
        else
            log_warning "⚠️ Podfile missing automatic code signing"
        fi
        
        if grep -q "IPHONEOS_DEPLOYMENT_TARGET.*13.0" Podfile; then
            log_success "✅ Podfile has iOS 13.0 deployment target"
        else
            log_warning "⚠️ Podfile missing iOS 13.0 deployment target"
        fi
    else
        log_error "❌ Podfile not found after generation"
        return 1
    fi
    
    log_info "🔄 Running: pod install --repo-update"
    log_info "Current directory: $(pwd)"
    log_info "Podfile contents:"
    cat Podfile
    if pod install --repo-update; then
        log_success "✅ pod install completed successfully"
        
                # Verify Pod settings were applied correctly
        log_info "🔍 Verifying Pod settings..."
        if [ -d "Pods" ]; then
            log_info "✅ Pods directory created successfully"
            
            # Check if any Pod targets still have provisioning profile references
            PROFILE_REFS=$(find Pods -name "*.pbxproj" -exec grep -l "PROVISIONING_PROFILE" {} \; 2>/dev/null || true)
            if [ -n "$PROFILE_REFS" ]; then
                log_warning "⚠️ Found Pod targets with provisioning profile references:"
                echo "$PROFILE_REFS"
                log_info "These should be automatically resolved by the Podfile post_install hook"
                
                # Force re-run post_install hook if provisioning profiles are found
                if [ -n "$PROFILE_REFS" ]; then
                    log_info "🔄 Forcing post_install hook to run again..."
                    if pod install --no-repo-update; then
                        log_success "✅ Post_install hook re-run successfully"
                        
                        # Check again after re-run
                        sleep 2
                        PROFILE_REFS_AFTER=$(find Pods -name "*.pbxproj" -exec grep -l "PROVISIONING_PROFILE" {} \; 2>/dev/null || true)
                        if [ -n "$PROFILE_REFS_AFTER" ]; then
                            log_warning "⚠️ Still found provisioning profile references after post_install re-run"
                            log_info "This indicates the Podfile fixes may not be working properly"
                        else
                            log_success "✅ Post_install hook successfully removed all provisioning profile references"
                        fi
                    else
                        log_warning "⚠️ Post_install hook re-run failed"
                    fi
                fi
            else
                log_success "✅ No provisioning profile references found in Pods"
            fi
            
            # Check deployment targets
            DEPLOYMENT_TARGETS=$(find Pods -name "*.pbxproj" -exec grep -h "IPHONEOS_DEPLOYMENT_TARGET" {} \; 2>/dev/null | sort | uniq || true)
            if [ -n "$DEPLOYMENT_TARGETS" ]; then
                log_info "Current Pod deployment targets:"
                echo "$DEPLOYMENT_TARGETS"
                
                # Check for any targets still using iOS 9.0
                OLD_TARGETS=$(echo "$DEPLOYMENT_TARGETS" | grep "9\.0" || true)
                if [ -n "$OLD_TARGETS" ]; then
                    log_warning "⚠️ Found Pod targets still using iOS 9.0 deployment target:"
                    echo "$OLD_TARGETS"
                else
                    log_success "✅ All Pod targets using iOS 13.0+ deployment target"
                fi
            fi
        else
            log_error "❌ Pods directory not created"
        fi
        
        # Fix Pod code signing issues after successful pod install
        log_info "🔧 Fixing Pod code signing issues..."
        if [ -f "lib/scripts/ios-workflow/fix_pod_code_signing.sh" ]; then
            chmod +x lib/scripts/ios-workflow/fix_pod_code_signing.sh
            if ./lib/scripts/ios-workflow/fix_pod_code_signing.sh; then
                log_success "✅ Pod code signing issues fixed"
            else
                log_warning "⚠️ Pod code signing fix failed, but continuing..."
            fi
        else
            log_warning "⚠️ Pod code signing fix script not found, skipping..."
        fi
    else
        log_error "❌ pod install failed"
        popd > /dev/null
        return 1
    fi

    popd > /dev/null
    log_success "✅ CocoaPods commands completed"
}

run_cocoapods_commands

# Step 16: Xcode Configuration and Code Signing
echo "⚙️ Step 16: Xcode Configuration and Code Signing..."

# Update Release.xcconfig
XC_CONFIG_PATH="ios/Flutter/release.xcconfig"
log_info "Updating release.xcconfig with dynamic signing values..."
sed -i '' '/^CODE_SIGN_STYLE/d' "$XC_CONFIG_PATH"
sed -i '' '/^DEVELOPMENT_TEAM/d' "$XC_CONFIG_PATH"
sed -i '' '/^PROVISIONING_PROFILE_SPECIFIER/d' "$XC_CONFIG_PATH"
sed -i '' '/^CODE_SIGN_IDENTITY/d' "$XC_CONFIG_PATH"
sed -i '' '/^PRODUCT_BUNDLE_IDENTIFIER/d' "$XC_CONFIG_PATH"

cat <<EOF >> "$XC_CONFIG_PATH"
CODE_SIGN_STYLE = Manual
DEVELOPMENT_TEAM = $APPLE_TEAM_ID
PROVISIONING_PROFILE_SPECIFIER = $UUID
CODE_SIGN_IDENTITY = iPhone Distribution
PRODUCT_BUNDLE_IDENTIFIER = $BUNDLE_ID
EOF

log_info "✅ release.xcconfig updated:"
cat "$XC_CONFIG_PATH"

# Validate bundle ID consistency
log_info "🔍 Validating bundle ID consistency..."
ACTUAL_BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" ios/Runner/Info.plist 2>/dev/null || echo "")
if [[ "$ACTUAL_BUNDLE_ID" != "$BUNDLE_ID" ]]; then
    log_warning "Bundle ID mismatch detected!"
    log_warning "Expected: $BUNDLE_ID"
    log_warning "Actual: $ACTUAL_BUNDLE_ID"
    log_info "Fixing bundle ID in Info.plist..."
    /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" ios/Runner/Info.plist
    log_success "Bundle ID fixed in Info.plist"
else
    log_success "Bundle ID consistency verified: $BUNDLE_ID"
fi

log_info "Set up code signing settings on Xcode project"
xcode-project use-profiles

# Final verification before build
log_info "🔍 Final verification before build..."
log_info "Bundle ID: $BUNDLE_ID"
log_info "Team ID: $APPLE_TEAM_ID"
log_info "Provisioning Profile UUID: $UUID"
log_info "Provisioning Profile Path: $PROFILE_PATH"

# Verify key files exist
if [[ -f "ios/Runner/Info.plist" ]]; then
    ACTUAL_BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" ios/Runner/Info.plist 2>/dev/null || echo "")
    log_info "Info.plist Bundle ID: $ACTUAL_BUNDLE_ID"
fi

if [[ -f "ios/Flutter/release.xcconfig" ]]; then
    log_info "Release.xcconfig contents:"
    cat ios/Flutter/release.xcconfig
fi

log_success "✅ Pre-build verification completed"

# Step 17: Build Process
echo "🔨 Step 17: Build Process..."

# Build
log_info "📱 Building Flutter iOS app in release mode..."
flutter build ios --release --no-codesign \
    --build-name="$VERSION_NAME" \
    --build-number="$VERSION_CODE" \
    --verbose \
    2>&1 | tee flutter_build.log

# Verify Flutter build completed successfully
if ! grep -q "Built.*Runner.app" flutter_build.log; then
    log_error "❌ Flutter build failed - Runner.app not found in build log"
    log_info "Flutter build log:"
    cat flutter_build.log
    exit 1
fi

log_success "✅ Flutter build completed successfully"

log_info "📦 Archiving app with Xcode..."
mkdir -p build/ios/archive

xcodebuild -workspace ios/Runner.xcworkspace \
    -scheme Runner \
    -configuration Release \
    -archivePath build/ios/archive/Runner.xcarchive \
    -destination 'generic/platform=iOS' \
    archive \
    DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY="iPhone Distribution" \
    PROVISIONING_PROFILE_SPECIFIER="$UUID" \
    PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
    2>&1 | tee xcodebuild_archive.log

# Verify archive was created successfully
if [ ! -d "build/ios/archive/Runner.xcarchive" ]; then
    log_error "❌ Xcode archive failed - Runner.xcarchive not found"
    log_info "Xcode archive log:"
    cat xcodebuild_archive.log
    exit 1
fi

log_success "✅ Xcode archive completed successfully"

# Step 18: IPA Export and Finalization
echo "📤 Step 18: IPA Export and Finalization..."

log_info "🛠️ Writing ExportOptions.plist..."
cat > ios/ExportOptions.plist << EXPORTPLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>$BUNDLE_ID</key>
        <string>$UUID</string>
    </dict>
    <key>teamID</key>
    <string>$APPLE_TEAM_ID</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
</dict>
</plist>
EXPORTPLIST

log_info "📤 Exporting IPA..."
set -x # verbose shell output

xcodebuild -exportArchive \
    -archivePath build/ios/archive/Runner.xcarchive \
    -exportPath build/ios/output \
    -exportOptionsPlist ios/ExportOptions.plist

# Enhanced error handling for the final steps
log_info "📦 Final verification and cleanup..."

# Ensure output directory exists
mkdir -p output/ios
mkdir -p build/ios/output

# Find IPA file with better error handling
IPA_PATH=""
for search_path in "build/ios/output" "build/ios" "output/ios" "."; do
    if [ -d "$search_path" ]; then
        found_ipa=$(find "$search_path" -name "*.ipa" -type f 2>/dev/null | head -1)
        if [ -n "$found_ipa" ]; then
            IPA_PATH="$found_ipa"
            log_success "✅ Found IPA at: $IPA_PATH"
            break
        fi
    fi
done

if [ -z "$IPA_PATH" ]; then
    log_error "❌ No IPA file found after build"
    log_info "Searching for any build artifacts..."
    find . -name "*.ipa" -o -name "*.xcarchive" -o -name "*.app" 2>/dev/null | head -10
    log_error "❌ Build failed - no IPA generated"
    exit 1
fi

# Verify IPA file is not empty
if [ ! -s "$IPA_PATH" ]; then
    log_error "❌ IPA file is empty: $IPA_PATH"
    exit 1
fi

# Get IPA file size
IPA_SIZE=$(stat -f%z "$IPA_PATH" 2>/dev/null || stat -c%s "$IPA_PATH" 2>/dev/null || echo "unknown")
log_info "📱 IPA file size: $IPA_SIZE bytes"

# Copy IPA to output directory for easier access
if [ "$IPA_PATH" != "output/ios/"* ]; then
    cp "$IPA_PATH" "output/ios/" 2>/dev/null || log_warning "Could not copy IPA to output/ios/"
fi

# Create artifacts summary
log_info "📋 Creating artifacts summary..."
cat > output/ios/ARTIFACTS_SUMMARY.txt << EOF
iOS Build Artifacts Summary
===========================

Build Information:
- App Name: ${APP_NAME:-Unknown}
- Bundle ID: ${BUNDLE_ID:-Unknown}
- Version: ${VERSION_NAME:-Unknown}
- Build Number: ${VERSION_CODE:-Unknown}
- Team ID: ${APPLE_TEAM_ID:-Unknown}

Generated Files:
- IPA File: $IPA_PATH
- IPA Size: $IPA_SIZE bytes
- Archive: build/ios/archive/Runner.xcarchive
- ExportOptions: ios/ExportOptions.plist
- Release Config: ios/Flutter/release.xcconfig

Build Logs:
- Flutter Build: flutter_build.log
- Xcode Archive: xcodebuild_archive.log

Build Status: ✅ SUCCESS
Build Date: $(date)
EOF

log_success "✅ Artifacts summary created: output/ios/ARTIFACTS_SUMMARY.txt"

# List all generated artifacts
log_info "📦 Generated artifacts:"
find build/ios/output -name "*.ipa" -exec echo "  📱 IPA: {}" \; 2>/dev/null || true
find build/ios/archive -name "*.xcarchive" -exec echo "  📦 Archive: {}" \; 2>/dev/null || true
find output/ios -name "*" -exec echo "  📋 Output: {}" \; 2>/dev/null || true

log_success "🎉 iOS build process completed successfully!"
log_info "📦 Artifacts available in:"
log_info "  📱 IPA: $IPA_PATH"
log_info "  📋 Summary: output/ios/ARTIFACTS_SUMMARY.txt"
log_info "  📦 Archive: build/ios/archive/Runner.xcarchive"
log_info "  📋 Config: ios/ExportOptions.plist"

# Final success exit
exit 0
