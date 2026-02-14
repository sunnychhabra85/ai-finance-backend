#!/bin/bash

set -e

echo "🚀 Starting AI Finance Backend Stack..."
echo ""

# Start all services
echo "1️⃣  Starting containers..."
docker-compose up -d

# Wait for postgres to be healthy
echo ""
echo "2️⃣  Waiting for PostgreSQL to be ready..."
sleep 10

for i in {1..30}; do
  if docker-compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; then
    echo "✅ PostgreSQL is ready!"
    break
  fi
  echo "   Attempt $i/30 - PostgreSQL not ready yet..."
  sleep 2
done

# Create databases with error suppression (databases might already exist)
echo ""
echo "3️⃣  Creating databases..."

docker-compose exec -T postgres psql -U postgres << 'EOF'
CREATE DATABASE authservicedb;
CREATE DATABASE uploadservicedb;
CREATE DATABASE parserworkerdb;
CREATE DATABASE analyticsservicedb;
CREATE DATABASE aiservicedb;
EOF

echo "✅ Databases created (or already exist)"

echo ""
echo "4️⃣  Waiting for services to stabilize..."
sleep 15

# Check status
echo ""
echo "📊 Service Status:"
docker-compose ps

echo ""
echo "✅ Stack is ready!"
echo ""
echo "📋 Available endpoints:"
echo "   API Gateway:        http://localhost"
echo "   Auth Service:       http://localhost:3001"
echo "   Upload Service:     http://localhost:3002"
echo "   Parser Worker:      http://localhost:3003"
echo "   Analytics Service:  http://localhost:3004"
echo "   AI Service:         http://localhost:3005"
echo "   PostgreSQL:         localhost:5432"
echo ""
echo "🔧 Useful commands:"
echo "   docker-compose logs -f auth-service     # View auth service logs"
echo "   docker-compose ps                       # View service status"
echo "   docker-compose down                     # Stop all services"
echo ""