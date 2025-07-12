#!/bin/bash

# Test script to verify PHP configuration detection and setup
# This script tests the logic from the PHP Ansible role

echo "🧪 Testing PHP Configuration Detection Logic"
echo "=============================================="

# Simulate the PHP version detection
echo "📋 Step 1: Detecting PHP version..."
if command -v php &> /dev/null; then
    PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;" 2>/dev/null || echo "unknown")
    echo "✅ PHP version detected: $PHP_VERSION"
else
    echo "❌ PHP not found in PATH"
    exit 1
fi

# Test configuration path detection
echo ""
echo "📋 Step 2: Checking PHP configuration paths..."

# Standard paths to check
APACHE_CONFIG="/etc/php/$PHP_VERSION/apache2/php.ini"
FPM_CONFIG="/etc/php/$PHP_VERSION/fpm/php.ini"
CLI_CONFIG="/etc/php/$PHP_VERSION/cli/php.ini"

echo "   Checking: $APACHE_CONFIG"
if [ -f "$APACHE_CONFIG" ]; then
    echo "   ✅ Apache config exists: $APACHE_CONFIG"
    PRIMARY_CONFIG="$APACHE_CONFIG"
elif [ -f "$FPM_CONFIG" ]; then
    echo "   ✅ FPM config exists: $FPM_CONFIG"
    PRIMARY_CONFIG="$FPM_CONFIG"
elif [ -f "$CLI_CONFIG" ]; then
    echo "   ✅ CLI config exists: $CLI_CONFIG"
    PRIMARY_CONFIG="$CLI_CONFIG"
else
    echo "   ❌ No standard PHP config found"
    PRIMARY_CONFIG=""
fi

# Fallback: search for any php.ini files
echo ""
echo "📋 Step 3: Searching for PHP configuration files..."
if [ -z "$PRIMARY_CONFIG" ]; then
    echo "   Searching for php.ini files in /etc/php..."
    PHP_CONFIGS=$(find /etc/php -name "php.ini" -type f 2>/dev/null || echo "")
    
    if [ -n "$PHP_CONFIGS" ]; then
        echo "   ✅ Found PHP configuration files:"
        echo "$PHP_CONFIGS" | while read -r config; do
            echo "      - $config"
        done
        
        # Prefer apache2 config if available
        APACHE_FALLBACK=$(echo "$PHP_CONFIGS" | grep apache2 | head -1)
        if [ -n "$APACHE_FALLBACK" ]; then
            PRIMARY_CONFIG="$APACHE_FALLBACK"
            echo "   ✅ Using Apache config: $PRIMARY_CONFIG"
        else
            PRIMARY_CONFIG=$(echo "$PHP_CONFIGS" | head -1)
            echo "   ✅ Using first found config: $PRIMARY_CONFIG"
        fi
    else
        echo "   ❌ No php.ini files found"
    fi
fi

# Test configuration directory creation
echo ""
echo "📋 Step 4: Testing configuration directory creation..."
CONFIG_DIR="/etc/php/$PHP_VERSION/apache2"
echo "   Checking directory: $CONFIG_DIR"

if [ -d "$CONFIG_DIR" ]; then
    echo "   ✅ Directory exists: $CONFIG_DIR"
elif [ -w "/etc/php/$PHP_VERSION" ] || [ -w "/etc/php" ] || [ -w "/etc" ]; then
    echo "   ✅ Directory can be created: $CONFIG_DIR"
else
    echo "   ❌ Cannot create directory: $CONFIG_DIR (permission denied)"
fi

# Test PHP modules
echo ""
echo "📋 Step 5: Checking required PHP modules..."
REQUIRED_MODULES=("mysql" "curl" "gd" "mbstring" "xml" "zip")

for module in "${REQUIRED_MODULES[@]}"; do
    if php -m | grep -q "^${module}$" 2>/dev/null; then
        echo "   ✅ Module available: $module"
    else
        echo "   ❌ Module missing: $module"
    fi
done

# Summary
echo ""
echo "📋 Summary:"
echo "==========="
echo "PHP Version: $PHP_VERSION"
echo "Primary Config: ${PRIMARY_CONFIG:-'None found'}"
echo "Config Directory: $CONFIG_DIR"

# Test WordPress PHP requirements
echo ""
echo "📋 WordPress PHP Requirements Check:"
echo "===================================="

# Check PHP version compatibility
if [[ "$PHP_VERSION" > "7.4" ]]; then
    echo "✅ PHP version compatible with WordPress ($PHP_VERSION >= 7.4)"
else
    echo "❌ PHP version may not be compatible with WordPress ($PHP_VERSION < 7.4)"
fi

# Check memory limit
MEMORY_LIMIT=$(php -r "echo ini_get('memory_limit');" 2>/dev/null || echo "unknown")
echo "Current memory limit: $MEMORY_LIMIT"

# Check upload limit
UPLOAD_LIMIT=$(php -r "echo ini_get('upload_max_filesize');" 2>/dev/null || echo "unknown")
echo "Current upload limit: $UPLOAD_LIMIT"

# Check post limit
POST_LIMIT=$(php -r "echo ini_get('post_max_size');" 2>/dev/null || echo "unknown")
echo "Current post limit: $POST_LIMIT"

echo ""
echo "🎉 PHP Configuration Test Complete!"
echo "==================================="
echo "💡 This test simulates the logic used by the Ansible PHP role."
echo "   Any issues found here will be automatically handled during deployment."
