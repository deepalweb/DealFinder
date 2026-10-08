# DealFinder production image: Express API + Next.js web app in one container.
# backend/server.js starts the Next.js standalone server and proxies non-API requests to it.
# Built and deployed by wrangler (see cloudflare/README.md).

FROM node:20-alpine AS web
WORKDIR /src/frontend-next
COPY frontend-next/package*.json ./
RUN npm ci --legacy-peer-deps
COPY frontend-next/ ./
ENV NODE_ENV=production \
    NEXT_PUBLIC_GA_ID=G-KW321NZHVV
RUN npm run build

FROM node:20-alpine
WORKDIR /app
COPY backend/package*.json backend/
RUN cd backend && npm ci --omit=dev && npm cache clean --force
COPY backend/ backend/
# Layout expected by server.js: ../frontend-next/server.js
COPY --from=web /src/frontend-next/.next/standalone/ frontend-next/
COPY --from=web /src/frontend-next/.next/static/ frontend-next/.next/static/
COPY --from=web /src/frontend-next/public/ frontend-next/public/

ENV NODE_ENV=production \
    PORT=8080
EXPOSE 8080
WORKDIR /app/backend
CMD ["node", "server.js"]
