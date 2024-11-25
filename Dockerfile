#############
# Nginx Builder
#############

FROM darkclip/nginx-builder:latest AS nginxbuilder

#############
# Final Image
#############

FROM debian:bookworm-slim AS final
LABEL maintainer="darkclip <darkclip@gmail.com>"

SHELL ["/bin/bash", "-eo", "pipefail", "-c"]

ARG TARGETPLATFORM
ARG OPENRESTY_VERSION=1.25.3.2
# Fixed lua version for openresty 1.25
# CrowdSec only support lua 5.1
ARG LUAROCKS_VERSION=3.11.1
ARG CROWDSEC_VERSION=v1.0.5
ARG ACME_VERSION=3.0.9

ENV OPENRESTY_VERSION=${OPENRESTY_VERSION}
ENV LUAROCKS_VERSION=${LUAROCKS_VERSION}
ENV CROWDSEC_VERSION=${CROWDSEC_VERSION}
ENV ACME_VERSION=${ACME_VERSION}
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
ENV CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
ENV NGX_HOME=/opt/openresty
ENV LUALIB=${NGX_HOME}/lualib
ENV NGX_CONF=/etc/nginx
ENV CROWDSEC_DATA=/data/crowdsec
ENV ACME_HOME=/opt/acme
ENV LE_WORKING_DIR=${ACME_HOME}
ENV ACME_CONFIG_HOME=/data/acme
ENV LE_CONFIG_HOME=${ACME_CONFIG_HOME}
ENV CERT_HOME=${ACME_CONFIG_HOME}/certs
ENV PATH=/data/bin:${ACME_HOME}:${NGX_HOME}/bin:${PATH}
ENV SHELL=/usr/bin/bash

COPY --from=nginxbuilder /tmp /tmp
COPY build/rootfs /

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
    tini \
    ca-certificates \
    curl \
    tzdata \
    micro \
    unzip \
    xz-utils \
    jq \
    apache2-utils \
    openssl \
    zlib1g \
    libpcre3 \
    lua5.1 \
    liblua5.1-0 \
    libreadline8 \
    libmaxminddb0 \
    perl \
    cron \
    socat \
    gettext-base \
    modsecurity-crs \
    libmodsecurity3 \
    ssdeep \
    libxml2 \
    libpcre2-8-0 \
    && apt-get install --no-install-recommends -y gcc libc6-dev make gettext \
    && pushd /tmp/luarocks \
    && make install \
    && popd \
    && pushd /tmp/openresty \
    && make install \
    && popd \
    && luarocks install lua-resty-openssl \
    && luarocks install lua-resty-openidc \
    && useradd -s /usr/sbin/nologin nginx \
    && mkdir -p "${CROWDSEC_DATA}" "${ACME_HOME}" "${ACME_CONFIG_HOME}" \
    && /tmp/install-release.sh -r "crowdsecurity/cs-openresty-bouncer" -t "${CROWDSEC_VERSION}" -p /tmp/crowdsec -d 0 \
    && pushd /tmp/crowdsec \
    && ./install.sh --docker --LIB_PATH="${LUALIB}" --NGINX_CONF_DIR="${NGX_CONF}/conf.d" --CONFIG_PATH="${CROWDSEC_DATA}" --DATA_PATH="${CROWDSEC_DATA}" \
    && popd \
    && /tmp/install-release.sh -r "acmesh-official/acme.sh" -t "${ACME_VERSION}" -k tarball -p /tmp/acme -o acme.tar.gz -d 0 \
    && pushd /tmp/acme \
    && ./acme.sh --install --no-profile --force --home "${ACME_HOME}" --config-home "${ACME_CONFIG_HOME}" --cert-home "${CERT_HOME}" \
    && popd \
    && sed -i 's|ENABLED=.*|ENABLED=false|' "${CROWDSEC_DATA}"/crowdsec-openresty-bouncer.conf \
    && sed -i 's|MODE=.*|MODE=stream|' "${CROWDSEC_DATA}"/crowdsec-openresty-bouncer.conf \
    && acme.sh --set-default-ca --server letsencrypt \
    && apt-get remove -y gcc libc6-dev make gettext \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -r /data/openresty \
    && cp -r /data /data-install \
    && cp -r /data-preset/nginx/* ${NGX_CONF} \
    && rm -r /data-preset \
    && rm -rf /tmp/* /var/cache/* /var/log/* /var/lib/apt/lists/* /var/lib/dpkg/status-old

WORKDIR /data
VOLUME [ "/data" ]
EXPOSE 80 443/tcp 443/udp
ENTRYPOINT [ "tini", "--" ]
CMD [ "init.sh" ]
