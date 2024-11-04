#############
# Nginx Builder
#############

FROM debian:bookworm-slim

ARG OPENRESTY_VERSION
ARG LUA_VERSION
ARG LUAROCKS_VERSION

RUN apt-get update \
    && apt-get install -y \
    build-essential \
    ca-certificates \
    libncurses-dev \
    libpcre3-dev \
    libreadline-dev \
    libssl-dev \
    openssl unzip \
    wget \
    zlib1g-dev \
    git \
    libmaxminddb-dev

# Lua build
COPY ./scripts/build-lua /tmp/build-lua
RUN /tmp/build-lua

# Nginx build
COPY ./scripts/build-openresty /tmp/build-openresty
RUN /tmp/build-openresty

COPY ./scripts/install-lua /tmp/install-lua
COPY ./scripts/install-openresty /tmp/install-openresty
COPY ./scripts/install-github-release.sh /tmp/
