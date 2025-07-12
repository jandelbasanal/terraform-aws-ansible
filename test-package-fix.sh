#!/bin/bash
# Test the package installation function fix

echo "🧪 Testing Package Installation Function Fix"
echo "============================================="

# Test case 1: Normal package name
echo "Test 1: Normal package name"
package="boto3"
cleaned=$(echo "$package" | sed "s/^'//; s/'$//")
echo "Original: $package"
echo "Cleaned: $cleaned"
echo ""

# Test case 2: Package with version constraints
echo "Test 2: Package with version constraints"
package="ansible>=4.0.0,<6.0.0"
cleaned=$(echo "$package" | sed "s/^'//; s/'$//")
echo "Original: $package"
echo "Cleaned: $cleaned"
echo ""

# Test case 3: Package with single quotes (the problematic case)
echo "Test 3: Package with single quotes (problematic case)"
package="'ansible>=4.0.0,<6.0.0'"
cleaned=$(echo "$package" | sed "s/^'//; s/'$//")
echo "Original: $package"
echo "Cleaned: $cleaned"
echo ""

# Test case 4: Package with pip arguments
echo "Test 4: Package with pip arguments"
package="--force-reinstall --no-deps six"
cleaned=$(echo "$package" | sed "s/^'//; s/'$//")
echo "Original: $package"
echo "Cleaned: $cleaned"
echo ""

echo "✅ All tests completed!"
echo ""
echo "The fix removes single quotes from package names, which was causing:"
echo "ERROR: Invalid requirement: \"'ansible>=4.0.0,<6.0.0'\""
echo ""
echo "Now it should work correctly with the cleaned package names."
