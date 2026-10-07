FROM node:24.21.0-alpine as base
WORKDIR /app

FROM base as runtime
COPY . .
RUN --mount=type=cache,target=/root/.npm \
    npm ci --omit=dev --ignore-scripts && npm exec -- prisma generate && npm run db:migrate

FROM runtime as dist
RUN --mount=type=cache,target=/root/.npm \
    npm ci --ignore-scripts && npm exec -- tsup

FROM base as release

COPY app.js .
COPY package.json .
COPY package-lock.json .
COPY --from=dist /app/dist ./dist
COPY --from=dist /app/prisma ./prisma
COPY --from=runtime /app/node_modules ./node_modules

CMD npm run start
