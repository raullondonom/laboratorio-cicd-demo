# Etapa 1: build con Node 20
FROM node:20-alpine AS build
WORKDIR /app

ARG VITE_API_URL=http://localhost:8000
ENV VITE_API_URL=$VITE_API_URL

COPY package.json package-lock.json* ./
RUN npm install --no-audit --no-fund

COPY tsconfig.json vite.config.ts index.html ./
COPY src ./src

RUN npm run build

# Etapa 2: nginx servidor estatico
FROM nginx:1.27-alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
