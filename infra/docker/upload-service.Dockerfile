FROM node:20-alpine AS builder

WORKDIR /build

COPY package*.json ./
COPY tsconfig.base.json ./
COPY apps/upload-service ./apps/upload-service
COPY packages ./packages

RUN npm ci
RUN npm run build --workspace=apps/upload-service

# ============================================
# Stage 2: Runtime
# ============================================
FROM node:20-alpine

WORKDIR /app

RUN addgroup -g 1001 -S nodejs && \
    adduser -S nestjs -u 1001

COPY package*.json ./

RUN npm ci --only=production && \
    npm cache clean --force

COPY --from=builder /build/apps/upload-service/dist ./dist
COPY --from=builder /build/apps/upload-service/prisma ./prisma
COPY --chown=nestjs:nodejs . .

USER nestjs

HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3002/health', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"

EXPOSE 3002

CMD ["node", "dist/main.js"]