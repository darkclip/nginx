#############
# Nginx Builder
#############

FROM debian:bookworm-slim

SHELL ["/bin/bash", "-eo", "pipefail", "-c"]

ARG OPENRESTY_VERSION=1.25.3.2
ARG LUA_VERSION=5.1.5
ARG LUAROCKS_VERSION=3.11.1

COPY build /tmp/

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
    && mkdir stage \
    && mv /tmp/scripts/install-release.sh /stage \
    && ./stage/install-release.sh -u "http://www.lua.org/ftp/lua-${LUA_VERSION}.tar.gz" -p /stage/lua -d 0 \
    && pushd /stage/lua \
    && make linux test \
    && make install \
    && popd \
    && ./stage/install-release.sh -u "http://luarocks.github.io/luarocks/releases/luarocks-${LUAROCKS_VERSION}.tar.gz" -p /stage/luarocks -d 0 \
    && pushd /stage/luarocks \
    && ./configure \
    && make \
    && popd \
    && ./tmp/scripts/build-openresty.sh \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /tmp

