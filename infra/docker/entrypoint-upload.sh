#!/bin/sh
set -e

echo "Running Prisma migrations for upload-service..."
npx prisma db push --schema=apps/upload-service/prisma/schema.prisma --skip-generate --accept-data-loss || echo "Migration failed or already applied"

echo "Starting upload-service..."
exec node apps/upload-service/dist/main.js
