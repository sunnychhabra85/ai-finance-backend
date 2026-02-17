#!/bin/bash

# Get service URLs
AUTH_URL=$(kubectl get svc auth-service -n ai-finance -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
UPLOAD_URL=$(kubectl get svc upload-service -n ai-finance -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
PARSE_URL=$(kubectl get svc parser-worker -n ai-finance -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
ANALYTICS_URL=$(kubectl get svc analytics-service -n ai-finance -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
AI_URL=$(kubectl get svc ai-service -n ai-finance -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "🧪 Testing AI Finance APIs"
echo "=================================="
echo ""
echo "Service URLs:"
echo "  Auth:      http://$AUTH_URL"
echo "  Upload:    http://$UPLOAD_URL"
echo "  Parser:    http://$PARSE_URL"
echo "  Analytics: http://$ANALYTICS_URL"
echo "  AI:        http://$AI_URL"
echo ""

# Test 1: Health checks
echo "1️⃣  Testing Health Endpoints..."
echo "─────────────────────────────────"

echo ""
echo "Auth Service:"
curl -s http://$AUTH_URL/health
echo ""
echo ""

echo "Upload Service:"
curl -s http://$UPLOAD_URL/health
echo ""
echo ""

echo "Parser Service:"
curl -s http://$PARSE_URL/health
echo ""
echo ""

echo "Analytics Service:"
curl -s http://$ANALYTICS_URL/health
echo ""
echo ""

echo "AI Service:"
curl -s http://$AI_URL/health
echo ""
echo ""

# Test 2: Register user
echo "2️⃣  Registering User..."
echo "─────────────────────────────────"

REGISTER_RESPONSE=$(curl -s -X POST http://$AUTH_URL/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testuser@example.com",
    "password": "Password123!",
    "firstName": "Test",
    "lastName": "User"
  }')

echo "Response:"
echo "$REGISTER_RESPONSE"
echo ""
echo ""

# Test 3: Login
echo "3️⃣  Logging In..."
echo "─────────────────────────────────"

LOGIN_RESPONSE=$(curl -s -X POST http://$AUTH_URL/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testuser@example.com",
    "password": "Password123!"
  }')

echo "Response:"
echo "$LOGIN_RESPONSE"
echo ""
echo ""

# Try to extract JWT token (basic parsing without jq)
JWT_TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

if [ -z "$JWT_TOKEN" ]; then
    JWT_TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
fi

if [ -z "$JWT_TOKEN" ]; then
    echo "⚠️  Could not extract JWT token from response"
    echo "Please extract manually and set: export JWT_TOKEN=your_token"
    JWT_TOKEN="YOUR_JWT_TOKEN_HERE"
else
    echo "✅ JWT Token extracted: $JWT_TOKEN"
    echo ""
fi

echo ""

# Test 4: Get current user
echo "4️⃣  Getting Current User..."
echo "─────────────────────────────────"

if [ "$JWT_TOKEN" != "YOUR_JWT_TOKEN_HERE" ]; then
    echo "Using token: $JWT_TOKEN"
    curl -s -H "Authorization: Bearer $JWT_TOKEN" \
      http://$AUTH_URL/auth/me
else
    echo "⚠️  Token not available, skipping authenticated request"
fi

echo ""
echo ""

# Test 5: Test other services
echo "5️⃣  Testing Other Services..."
echo "─────────────────────────────────"

if [ "$JWT_TOKEN" != "YOUR_JWT_TOKEN_HERE" ]; then
    echo "Analytics Summary:"
    curl -s -H "Authorization: Bearer $JWT_TOKEN" \
      http://$ANALYTICS_URL/analytics/summary
    echo ""
    echo ""

    echo "AI Recommendations:"
    curl -s -H "Authorization: Bearer $JWT_TOKEN" \
      http://$AI_URL/ai/recommendations
    echo ""
    echo ""
else
    echo "⚠️  Token not available, skipping authenticated requests"
fi

echo "✅ Tests completed!"
echo ""
echo "If you got errors, check:"
echo "  1. kubectl get pods -n ai-finance"
echo "  2. kubectl logs deployment/auth-service -n ai-finance"
echo "  3. Service URLs are correct"