FROM node:20-alpine AS builder

WORKDIR /build

COPY package*.json ./
COPY tsconfig.base.json ./
COPY apps/analytics-service ./apps/analytics-service
COPY packages ./packages

RUN npm ci
RUN npm run build --workspace=apps/analytics-service

FROM node:20-alpine

WORKDIR /app

RUN addgroup -g 1001 -S nodejs && \
    adduser -S nestjs -u 1001

COPY package*.json ./

RUN npm ci --only=production && \
    npm cache clean --force

COPY --from=builder /build/apps/analytics-service/dist ./dist
COPY --from=builder /build/apps/analytics-service/prisma ./prisma
COPY --chown=nestjs:nodejs . .

USER nestjs

HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3004/health', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"

EXPOSE 3004

CMD ["node", "dist/main.js"]