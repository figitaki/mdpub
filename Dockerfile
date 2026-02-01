# syntax=docker/dockerfile:1

ARG ELIXIR_VERSION=1.18.1
ARG OTP_VERSION=27.2
ARG DEBIAN_VERSION=bookworm-20250113-slim

FROM hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION} AS build

WORKDIR /app
ENV MIX_ENV=prod

RUN apt-get update -y && apt-get install -y --no-install-recommends \
    build-essential git \
  && rm -rf /var/lib/apt/lists/*

RUN mix local.hex --force && mix local.rebar --force

COPY mix.exs mix.lock ./
RUN mix deps.get --only prod
RUN mix deps.compile

COPY lib ./lib
COPY priv ./priv
COPY content ./content

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
    MDPUB_WATCH=false

COPY --from=build /app/_build/prod/rel/mdpub ./

EXPOSE 4000

# Use foreground so the release stays attached as PID 1 in containers
CMD ["/app/bin/mdpub", "foreground"]
