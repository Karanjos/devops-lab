# ---- Stage 1: build the static site ---------------------------------------------------
FROM node:22-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

# ---- Stage 2: serve it with Nginx -----------------------------------------------------
FROM nginx:1.27-alpine
ENV BACKEND_HOST=backend:8080
# Files in /etc/nginx/templates/*.template are passed through envsubst into /etc/nginx/conf.d/.
COPY nginx.conf.template /etc/nginx/templates/default.conf.template
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
HEALTHCHECK --interval=15s --timeout=3s --retries=3 CMD wget -qO- http://127.0.0.1/healthz || exit 1
