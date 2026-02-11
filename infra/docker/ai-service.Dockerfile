FROM node:20-alpine AS builder

WORKDIR /build

COPY package*.json ./
COPY tsconfig.base.json ./
COPY apps/ai-service ./apps/ai-service
COPY packages ./packages

RUN npm ci
RUN npm run build --workspace=apps/ai-service

FROM node:20-alpine

WORKDIR /app

RUN addgroup -g 1001 -S nodejs && \
    adduser -S nestjs -u 1001

COPY package*.json ./

RUN npm ci --only=production && \
    npm cache clean --force

COPY --from=builder /build/apps/ai-service/dist ./dist
COPY --from=builder /build/apps/ai-service/prisma ./prisma
COPY --chown=nestjs:nodejs . .

USER nestjs

HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3005/health', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"

EXPOSE 3005

CMD ["node", "dist/main.js"]