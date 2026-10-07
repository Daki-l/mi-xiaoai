FROM node:24.21.0-alpine as base
ENV PRISMA_ENGINES_CHECKSUM_IGNORE_MISSING=1
ENV PRISMA_QUERY_ENGINE_BINARY=/app/prisma/engines/query-engine
ENV PRISMA_QUERY_ENGINE_LIBRARY=/app/prisma/engines/libquery_engine.so.node
ENV PRISMA_SCHEMA_ENGINE_BINARY=/app/prisma/engines/schema-engine

WORKDIR /app
ARG TARGETARCH

FROM base as runtime
COPY . .
RUN [ ! "$TARGETARCH" = "arm" ] && rm -rf ./prisma/engines || true
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
