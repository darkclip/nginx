#############
# Nginx Builder
#############

FROM debian:bookworm-slim

ARG OPENRESTY_VERSION
ARG LUA_VERSION
ARG LUAROCKS_VERSION

RUN apt-get update \
    && apt-get install -y \
    ca-certificates \
    curl \
    build-essential \
    libncurses-dev \
    libpcre3-dev \
    libreadline-dev \
    libssl-dev \
    openssl \
    xz-utils \
    zlib1g-dev \
    unzip \
    git \
    libmaxminddb-dev

COPY ./scripts/install-release.sh /tmp/

# Lua build
RUN  /tmp/install-release.sh -u "http://www.lua.org/ftp/lua-${LUA_VERSION}.tar.gz" -p /tmp/lua -d 0 \
    && cd /tmp/lua \
    && make linux test \
    && make install

RUN /tmp/install-release.sh -u "http://luarocks.github.io/luarocks/releases/luarocks-${LUAROCKS_VERSION}.tar.gz" -p /tmp/luarocks -d 0 \
    && cd /tmp/luarocks \
    && ./configure \
    && make

# Nginx build
COPY ./scripts/build-openresty.sh /tmp/build-openresty.sh
RUN /tmp/build-openresty.sh

