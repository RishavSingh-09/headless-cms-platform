FROM node:18-alpine AS base
WORKDIR /app
COPY apps/backend/package*.json ./
RUN npm install --omit=dev
COPY apps/backend/ ./
EXPOSE 1337
USER node
HEALTHCHECK --interval=30s --timeout=5s CMD wget -qO- http://localhost:1337/health || exit 1
CMD ["node", "src/server.js"]
