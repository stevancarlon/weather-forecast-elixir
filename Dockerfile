FROM elixir:1.15.8-otp-26-slim AS build

ARG DEBIAN_FRONTEND=noninteractive

ENV LANG=C.UTF-8 \
    MIX_ENV=prod \
    ERL_AFLAGS="+JMsingle true"

WORKDIR /app

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
      build-essential \
      ca-certificates \
      git \
    && rm -rf /var/lib/apt/lists/*

RUN mix local.hex --force \
    && mix local.rebar --force

COPY mix.exs mix.lock ./
RUN mix deps.get --only prod

COPY config config
RUN mix deps.compile

COPY lib lib
RUN mix compile \
    && mix release

FROM debian:bookworm-slim AS runtime

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
      ca-certificates \
      libncurses6 \
      libstdc++6 \
      openssl \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --system app \
    && useradd --system --gid app --home-dir /app app

WORKDIR /app

COPY --from=build --chown=app:app /app/_build/prod/rel/weather_forecast ./

USER app

ENV HOME=/app \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    START_SERVER=true

EXPOSE 4000

CMD ["bin/weather_forecast", "start"]
