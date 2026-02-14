FROM node:20-alpine AS builder

WORKDIR /build

COPY package*.json ./
COPY tsconfig.base.json ./
COPY apps ./apps
COPY packages ./packages

# Configure npm for better network resilience
RUN npm config set fetch-retries 5 && \
    npm config set fetch-retry-mintimeout 20000 && \
    npm config set fetch-retry-maxtimeout 120000 && \
    npm config set fetch-timeout 300000

RUN npm ci

# Remove any Windows-generated Prisma clients
RUN rm -rf apps/generated/analytics-client

# Regenerate Prisma for Linux
RUN npx prisma generate --schema=apps/analytics-service/prisma/schema.prisma

RUN npm run build --workspace=apps/analytics-service

FROM node:20-alpine

WORKDIR /app

# Install OpenSSL for Prisma
RUN apk add --no-cache openssl

RUN addgroup -g 1001 -S nodejs && \
    adduser -S nestjs -u 1001

COPY package*.json ./

# Configure npm for better network resilience
RUN npm config set fetch-retries 5 && \
    npm config set fetch-retry-mintimeout 20000 && \
    npm config set fetch-retry-maxtimeout 120000 && \
    npm config set fetch-timeout 300000

RUN npm ci --only=production --omit=dev && \
    npm cache clean --force

COPY --from=builder --chown=nestjs:nodejs /build/apps ./apps
COPY --from=builder --chown=nestjs:nodejs /build/packages ./packages

# Copy entrypoint script
COPY --chown=nestjs:nodejs infra/docker/entrypoint-analytics.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

RUN rm -rf apps/*/src packages/*/src

USER nestjs

HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3004/health', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})" || exit 1

EXPOSE 3004

CMD ["/app/entrypoint.sh"]