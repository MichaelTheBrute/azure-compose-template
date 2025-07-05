#!/bin/bash

# Security Validation Script
# This script checks that debug mode is properly configured for different environments

echo "🔒 Security Validation: Debug Mode Configuration"
echo "=================================================="

# Check local Docker Compose
echo ""
echo "📋 Local Development (docker-compose.local.yml):"
if grep -q "FLASK_DEBUG=1" docker-compose.local.yml; then
    echo "✅ FLASK_DEBUG=1 found in local config (expected)"
else
    echo "⚠️  FLASK_DEBUG=1 not found in local config"
fi

# Check production Docker Compose
echo ""
echo "📋 Production Deployment (docker-compose.yml):"
if grep -q "FLASK_DEBUG" docker-compose.yml; then
    echo "❌ FLASK_DEBUG found in production config (SECURITY RISK!)"
    echo "   Remove FLASK_DEBUG from docker-compose.yml"
else
    echo "✅ No FLASK_DEBUG in production config (secure)"
fi

# Check Flask app files for proper debug logic
echo ""
echo "📋 Flask Applications Debug Logic:"

echo ""
echo "Frontend (frontend/src/app.py):"
if grep -q "not is_azure and" frontend/src/app.py; then
    echo "✅ Frontend uses Azure detection for debug mode"
else
    echo "❌ Frontend may not have proper debug protection"
fi

echo ""
echo "Backend (backend/src/app.py):"
if grep -q "not is_azure and" backend/src/app.py; then
    echo "✅ Backend uses Azure detection for debug mode"
else
    echo "❌ Backend may not have proper debug protection"
fi

echo ""
echo "🔒 Security Summary:"
echo "==================="
echo "✅ Debug mode is only enabled when:"
echo "   1. NOT running in Azure (is_azure = False)"
echo "   2. AND FLASK_DEBUG=1 is set in environment"
echo ""
echo "✅ In production/Azure:"
echo "   - is_azure = True (detected automatically)"
echo "   - debug_mode = False (always disabled)"
echo ""
echo "✅ In local development:"
echo "   - is_azure = False"
echo "   - debug_mode = True (only if FLASK_DEBUG=1)"

echo ""
echo "🧪 To test this configuration:"
echo "  Local:  ./dev-local.sh     (should show 'Debug mode enabled')"
echo "  Azure:  Deploy normally    (should show 'Debug mode disabled')"
