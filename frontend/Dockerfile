# syntax=docker/dockerfile:1

# ---- Stage 1: build the static React bundle ----
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm install --no-audit --no-fund
COPY . .
RUN npm run build

# ---- Stage 2: unprivileged nginx serves the bundle (runs as non-root, port 8080) ----
FROM nginxinc/nginx-unprivileged:1.27-alpine
# API_URL is injected into the nginx config at container start (envsubst on /etc/nginx/templates).
ENV API_URL=http://backend:8000
COPY nginx.conf.template /etc/nginx/templates/default.conf.template
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 8080
HEALTHCHECK --interval=15s --timeout=3s --retries=5 \
  CMD wget -q --spider http://127.0.0.1:8080/ || exit 1
