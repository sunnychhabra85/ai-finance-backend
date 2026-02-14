#!/bin/sh
set -e

echo "Running Prisma migrations for analytics-service..."
npx prisma db push --schema=apps/analytics-service/prisma/schema.prisma --skip-generate --accept-data-loss || echo "Migration failed or already applied"

echo "Starting analytics-service..."
exec node apps/analytics-service/dist/main.js
