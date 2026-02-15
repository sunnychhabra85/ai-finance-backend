#!/bin/sh
set -e

echo "Running Prisma migrations for analytics-service..."
npx prisma migrate deploy --schema=apps/analytics-service/prisma/schema.prisma || echo "Migration failed or already applied"

echo "Starting analytics-service..."
exec node apps/analytics-service/dist/main.js
