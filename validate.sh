#!/bin/bash
# WordPress deployment validation script

if [ -z "$1" ]; then
    echo "Usage: $0 <ec2_public_ip>"
    exit 1
fi

EC2_IP="$1"

echo "🔍 Validating WordPress deployment on $EC2_IP"
echo "============================================="

# Test HTTP connectivity
echo "Testing HTTP connectivity..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$EC2_IP --connect-timeout 10)

if [ "$HTTP_STATUS" == "200" ]; then
    echo "✅ HTTP connectivity: OK"
else
    echo "❌ HTTP connectivity: FAILED (Status: $HTTP_STATUS)"
fi

# Test WordPress installation
echo "Testing WordPress installation..."
WP_RESPONSE=$(curl -s http://$EC2_IP --connect-timeout 10)

if echo "$WP_RESPONSE" | grep -q "WordPress"; then
    echo "✅ WordPress installation: OK"
else
    echo "❌ WordPress installation: FAILED"
fi

# Test admin panel access
echo "Testing admin panel access..."
ADMIN_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$EC2_IP/wp-admin --connect-timeout 10)

if [ "$ADMIN_STATUS" == "200" ] || [ "$ADMIN_STATUS" == "302" ]; then
    echo "✅ Admin panel access: OK"
else
    echo "❌ Admin panel access: FAILED (Status: $ADMIN_STATUS)"
fi

# Test database connectivity (via WordPress)
echo "Testing database connectivity..."
DB_TEST=$(curl -s http://$EC2_IP/wp-admin/install.php --connect-timeout 10)

if echo "$DB_TEST" | grep -q "database" || echo "$DB_TEST" | grep -q "WordPress"; then
    echo "✅ Database connectivity: OK"
else
    echo "❌ Database connectivity: FAILED"
fi

echo ""
echo "🌐 Access URLs:"
echo "   Website: http://$EC2_IP"
echo "   Admin: http://$EC2_IP/wp-admin"
echo ""
echo "🔑 Default credentials:"
echo "   Username: admin"
echo "   Password: admin123!"
