#############
# Nginx Builder
#############

FROM debian:bookworm-slim

ARG OPENRESTY_VERSION=1.25.3.2
ARG LUA_VERSION=5.1.5
ARG LUAROCKS_VERSION=3.11.1

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
    ca-certificates \
    curl \
    nano \
    git \
    unzip \
    xz-utils \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    libpcre3-dev \
    libreadline-dev

COPY build /tmp/

# Lua build
RUN  /tmp/scripts/install-release.sh -u "http://www.lua.org/ftp/lua-${LUA_VERSION}.tar.gz" -p /tmp/lua -d 0 \
    && cd /tmp/lua \
    && make linux test \
    && make install

RUN /tmp/scripts/install-release.sh -u "http://luarocks.github.io/luarocks/releases/luarocks-${LUAROCKS_VERSION}.tar.gz" -p /tmp/luarocks -d 0 \
    && cd /tmp/luarocks \
    && ./configure \
    && make

# Nginx build
RUN /tmp/scripts/build-openresty.sh

