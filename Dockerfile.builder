#############
# Nginx Builder
#############

FROM debian:bookworm-slim

SHELL ["/bin/bash", "-eo", "pipefail", "-c"]

ARG OPENRESTY_VERSION=1.25.3.2
ARG LUA_VERSION=5.1.5
ARG LUAROCKS_VERSION=3.11.1

COPY build /build/

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
    ca-certificates \
    curl \
    micro \
    git \
    unzip \
    xz-utils \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    libpcre3-dev \
    libreadline-dev \
    && mv /build/scripts/install-release.sh /tmp/ \
    && ./tmp/install-release.sh -u "http://www.lua.org/ftp/lua-${LUA_VERSION}.tar.gz" -p /tmp/lua -d 0 \
    && pushd /tmp/lua \
    && make linux test \
    && make install \
    && popd \
    && ./tmp/install-release.sh -u "http://luarocks.github.io/luarocks/releases/luarocks-${LUAROCKS_VERSION}.tar.gz" -p /tmp/luarocks -d 0 \
    && pushd /tmp/luarocks \
    && ./configure \
    && make \
    && popd \
    && ./build/scripts/build-openresty.sh \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /build

