#!/bin/sh
set -e

echo "Running Prisma migrations for analytics-service..."
# Try migrate deploy first, if it fails due to baseline issue, use db push
if ! npx prisma migrate deploy --schema=apps/analytics-service/prisma/schema.prisma 2>&1 | tee /tmp/migration.log; then
    if grep -q "P3005" /tmp/migration.log; then
        echo "Database not empty, using db push to sync schema..."
        npx prisma db push --schema=apps/analytics-service/prisma/schema.prisma --skip-generate --accept-data-loss
    else
        echo "Migration completed or already applied"
    fi
fi

echo "Starting analytics-service..."
exec node apps/analytics-service/dist/main.js
