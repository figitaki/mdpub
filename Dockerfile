# syntax=docker/dockerfile:1

ARG ELIXIR_VERSION=1.18.1
ARG OTP_VERSION=27.2
ARG DEBIAN_VERSION=bookworm-20250113-slim

FROM hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION} AS build

WORKDIR /app
ENV MIX_ENV=prod

RUN apt-get update -y && apt-get install -y --no-install-recommends \
    build-essential git nodejs npm \
  && rm -rf /var/lib/apt/lists/*

RUN mix local.hex --force && mix local.rebar --force

COPY mix.exs mix.lock ./
RUN mix deps.get --only prod
RUN mix deps.compile

COPY package.json tailwind.config.js ./
RUN npm install

COPY lib ./lib
COPY assets ./assets
COPY priv ./priv
COPY content ./content

RUN npm run build:css
RUN mix compile
RUN mix release

FROM debian:${DEBIAN_VERSION} AS app

RUN apt-get update -y && apt-get install -y --no-install-recommends \
    ca-certificates \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app
ENV MIX_ENV=prod \
    LANG=C.UTF-8 \
    PORT=4000 \
    MDPUB_CONTENT_DIR=/app/content \
    MDPUB_WATCH=false \
    RELEASE_DISTRIBUTION=none

COPY --from=build /app/_build/prod/rel/mdpub ./
# Include demo content in the runtime image
COPY --from=build /app/content ./content

EXPOSE 4000

# "start" runs in the foreground; "daemon" would background itself.
CMD ["/app/bin/mdpub", "start"]
