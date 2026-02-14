#!/bin/sh
set -e

echo "Running Prisma migrations for auth-service..."
npx prisma db push --schema=apps/auth-service/prisma/schema.prisma --skip-generate --accept-data-loss || echo "Migration failed or already applied"

echo "Starting auth-service..."
exec node apps/auth-service/dist/main.js
