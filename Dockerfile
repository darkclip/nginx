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
COPY ./scripts/install-crowdsec_openresty_bouncer /tmp/install-crowdsec_openresty_bouncer
COPY ./scripts/install-github-release.sh /tmp/

#############
# Final Image
#############

FROM debian:bookworm-slim AS final
LABEL maintainer="darkclip <darkclip@gmail.com>"

SHELL ["/bin/bash", "-eo", "pipefail", "-c"]

ARG TARGETPLATFORM
ARG LUA_VERSION
ARG LUAROCKS_VERSION
ARG OPENRESTY_VERSION
ARG CROWDSEC_OPENRESTY_BOUNCER_VERSION
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
    CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt \
    LUA_VERSION=${LUA_VERSION} \
    LUAROCKS_VERSION=${LUAROCKS_VERSION} \
    OPENRESTY_VERSION=${OPENRESTY_VERSION} \
    CROWDSEC_OPENRESTY_BOUNCER_VERSION=${CROWDSEC_OPENRESTY_BOUNCER_VERSION} \
    ACMESH_HOME=/data/acme \
    LE_WORKING_DIR=/data/acme \
    ACMESH_CONFIG_HOME=/data/acme/conf \
    LE_CONFIG_HOME=/data/acme/conf \
    CERT_HOME=/data/acme/certs 

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
    && /tmp/install-crowdsec_openresty_bouncer \
    && useradd -s /usr/sbin/nologin nginx \
    && mkdir -p /tmp/acme "$ACMESH_CONFIG_HOME" \
    && /tmp/install-github-release.sh -r "acmesh-official/acme.sh" -m acme -k tarball -p /tmp/acme -o acme.tar.gz -d 0 \
    && pushd /tmp/acme \
    && ./acme.sh --install --no-profile --force --home "$ACMESH_HOME" --config-home "$ACMESH_CONFIG_HOME" --cert-home "$CERT_HOME" \
    && popd \
    && apt-get remove -y wget gettext libmaxminddb-dev gcc make git \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/cache/* /var/log/* /tmp/* /var/lib/dpkg/status-old

CMD service cron start && nginx -g "daemon off;"