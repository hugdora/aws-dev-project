# syntax=docker/dockerfile:1

FROM node:20-alpine

WORKDIR /app

COPY nest-app/package*.json ./

RUN npm ci

COPY nest-app/ .

RUN npm run build

ENV NODE_ENV=production

EXPOSE 3000

CMD ["node", "dist/main.js"]