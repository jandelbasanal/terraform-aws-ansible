#!/bin/bash
# Test SSH key path resolution

echo "🧪 Testing SSH Key Path Resolution"
echo "=================================="

if [ -z "$1" ]; then
    echo "Usage: $0 <ssh-key-path>"
    echo "Example: $0 wtv.pem"
    echo "Example: $0 ./wtv.pem"
    echo "Example: $0 ~/.ssh/key.pem"
    exit 1
fi

SSH_KEY_PATH="$1"
ORIGINAL_DIR=$(pwd)

echo "🔍 Test Details:"
echo "  Original directory: $ORIGINAL_DIR"
echo "  SSH key parameter: $SSH_KEY_PATH"

# Resolve path immediately
SSH_KEY_ABSOLUTE=$(realpath "$SSH_KEY_PATH")
echo "  Resolved absolute path: $SSH_KEY_ABSOLUTE"

# Check if file exists
if [ -f "$SSH_KEY_ABSOLUTE" ]; then
    echo "  ✅ SSH key found!"
    echo "  📋 File info:"
    ls -la "$SSH_KEY_ABSOLUTE"
else
    echo "  ❌ SSH key not found!"
    exit 1
fi

# Test path resolution after changing directories
echo ""
echo "🔄 Testing after directory change:"
cd /tmp
echo "  Current directory: $(pwd)"
echo "  SSH key path still resolves to: $SSH_KEY_ABSOLUTE"

if [ -f "$SSH_KEY_ABSOLUTE" ]; then
    echo "  ✅ SSH key still accessible!"
else
    echo "  ❌ SSH key no longer accessible!"
fi

# Return to original directory
cd "$ORIGINAL_DIR"
echo ""
echo "✅ Test completed successfully!"
echo "📋 Summary:"
echo "  - Original parameter: $SSH_KEY_PATH"
echo "  - Resolved absolute path: $SSH_KEY_ABSOLUTE"
echo "  - File exists: $([ -f "$SSH_KEY_ABSOLUTE" ] && echo "Yes" || echo "No")"
