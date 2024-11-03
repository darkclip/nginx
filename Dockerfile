#############
# Nginx Builder
#############

FROM debian:bookworm-slim AS nginxbuilder

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

#############
# Final Image
#############

FROM debian:bookworm-slim AS final
LABEL maintainer="darkclip <darkclip@gmail.com>"

SHELL ["/bin/bash", "-eo", "pipefail", "-c"]

ARG TARGETPLATFORM
ARG OPENRESTY_VERSION
ARG LUA_VERSION
ARG LUAROCKS_VERSION
ARG CROWDSEC_VERSION=1.0.5
ARG ACME_VERSION=3.0.9

ENV OPENRESTY_VERSION=$OPENRESTY_VERSION
ENV LUA_VERSION=$LUA_VERSION
ENV LUAROCKS_VERSION=$LUAROCKS_VERSION
ENV CROWDSEC_VERSION=$CROWDSEC_VERSION
ENV ACME_VERSION=$ACME_VERSION
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
ENV CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
ENV NGINX_CONF=/etc/nginx/conf.d
ENV LUALIB=/etc/nginx/lualib
ENV ACME_HOME=/data/acme
ENV LE_WORKING_DIR=/data/acme
ENV ACME_CONFIG_HOME=/data/acme/conf
ENV LE_CONFIG_HOME=/data/acme/conf
ENV CERT_HOME=/data/acme/certs
ENV CROWDSEC_DATA=/data/crowdsec

COPY --from=nginxbuilder /tmp /tmp

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    apache2-utils \
    ca-certificates \
    curl \
    figlet \
    jq \
    libncurses6 \
    libpcre3 \
    libreadline8 \
    openssl \
    perl \
    tzdata \
    unzip \
    zlib1g \
    xz-utils \
    socat \
    nano \
    cron \
    && apt-get clean \
    && apt-get update \
    && apt-get install -y wget gettext libmaxminddb-dev gcc make git \
    && /tmp/install-lua \
    && /tmp/install-openresty \
    && useradd -s /usr/sbin/nologin nginx \
    && mkdir -p /tmp/crowdsec "$CROWDSEC_DATA" /tmp/acme "$ACME_CONFIG_HOME" \
    && /tmp/install-github-release.sh -r "crowdsecurity/cs-openresty-bouncer" -t "$CROWDSEC_VERSION" -p /tmp/crowdsec -d 0 \
    && pushd /tmp/crowdsec \
    && ./install.sh --docker --NGINX_CONF_DIR="$NGINX_CONF" --LIB_PATH="$LUALIB" --CONFIG_PATH="$CROWDSEC_DATA" --DATA_PATH="$CROWDSEC_DATA" \
    && sed -i 's|ENABLED=.*|ENABLED=false|' "$CROWDSEC_DATA"/crowdsec-openresty-bouncer.conf \
    && popd \
    && /tmp/install-github-release.sh -r "acmesh-official/acme.sh" -t "$ACME_VERSION" -k tarball -p /tmp/acme -o acme.tar.gz -d 0 \
    && pushd /tmp/acme \
    && ./acme.sh --install --no-profile --force --home "$ACME_HOME" --config-home "$ACME_CONFIG_HOME" --cert-home "$CERT_HOME" \
    && popd \
    && apt-get remove -y wget gettext libmaxminddb-dev gcc make git \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/cache/* /var/log/* /tmp/* /var/lib/dpkg/status-old

CMD service cron start && nginx -g "daemon off;"
