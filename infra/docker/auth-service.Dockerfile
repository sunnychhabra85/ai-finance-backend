# ============================================
# Stage 1: Build
# ============================================
FROM node:20-alpine AS builder

WORKDIR /build

# Copy monorepo files
COPY package*.json ./
COPY tsconfig.base.json ./
COPY apps/auth-service ./apps/auth-service
COPY packages ./packages

# Install dependencies
RUN npm ci

# Build only the auth-service
RUN npm run build --workspace=apps/auth-service

# ============================================
# Stage 2: Runtime
# ============================================
FROM node:20-alpine

WORKDIR /app

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nestjs -u 1001

# Copy package files
COPY package*.json ./

# Install production dependencies only (no dev dependencies)
RUN npm ci --only=production && \
    npm cache clean --force

# Copy built application from builder stage
COPY --from=builder /build/apps/auth-service/dist ./dist

# Copy Prisma schema for runtime
COPY --from=builder /build/apps/auth-service/prisma ./prisma
COPY --chown=nestjs:nodejs . .

# Switch to non-root user
USER nestjs

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3001/health', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"

EXPOSE 3001

CMD ["node", "dist/main.js"]