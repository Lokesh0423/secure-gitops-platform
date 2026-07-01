# Build stage
FROM node:22-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev

# Runtime stage
FROM node:22-alpine

# Security: run as non-root user
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

WORKDIR /app

COPY --from=builder /app/node_modules ./node_modules
COPY src/ ./src/

# Remove npm's bundled internals from the runtime image.
# The app only needs `node` to run; npm is a build-time tool only,
# and its own internal dependencies (tar, glob, minimatch, picomatch, etc.)
# otherwise show up as false vulnerability findings in image scans.
RUN rm -rf /usr/local/lib/node_modules/npm \
    /usr/local/bin/npm \
    /usr/local/bin/npx \
    /opt/yarn*

RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:3000/health || exit 1

CMD ["node", "src/index.js"]
