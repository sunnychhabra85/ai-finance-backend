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

# Regenerate Prisma for Linux
# RUN npx prisma generate --schema=apps/parser-worker/prisma/schema.prisma

RUN npm run build --workspace=apps/parser-worker

FROM node:20-alpine

WORKDIR /app

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

RUN rm -rf apps/*/src packages/*/src

USER nestjs

HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3003/health', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})" || exit 1

EXPOSE 3003

CMD ["node", "apps/parser-worker/dist/main.js"]