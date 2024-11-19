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
ARG LUA_VERSION=5.4.7
ARG LUAROCKS_VERSION=3.11.1
ARG CROWDSEC_VERSION=v1.0.5
ARG ACME_VERSION=3.0.9
ARG MAXMIND_USER
ARG MAXMIND_TOKEN

ENV OPENRESTY_VERSION=${OPENRESTY_VERSION}
ENV LUA_VERSION=${LUA_VERSION}
ENV LUAROCKS_VERSION=${LUAROCKS_VERSION}
ENV CROWDSEC_VERSION=${CROWDSEC_VERSION}
ENV ACME_VERSION=${ACME_VERSION}
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
ENV CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
ENV LUALIB=/opt/openresty/lualib
ENV NGINX_CONF=/data/openresty/conf.d
ENV NGINX_LOG=/data/openresty/log
ENV NGINX_CACHE=/data/openresty/cache
ENV CROWDSEC_DATA=/data/crowdsec
ENV ACME_HOME=/opt/acme
ENV LE_WORKING_DIR=/opt/acme
ENV ACME_CONFIG_HOME=/data/acme
ENV LE_CONFIG_HOME=/data/acme
ENV CERT_HOME=/data/certs
ENV PATH=${ACME_HOME}:/opt/openresty/bin:${PATH}

COPY --from=nginxbuilder /tmp /tmp

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
    tini \
    ca-certificates \
    curl \
    tzdata \
    nano \
    unzip \
    xz-utils \
    jq \
    apache2-utils \
    openssl \
    zlib1g \
    libpcre3 \
    perl \
    cron \
    socat \
    libnginx-mod-http-geoip2 \
    libnginx-mod-stream-geoip2 \
    && /tmp/install-release.sh -a ${MAXMIND_USER}:${MAXMIND_TOKEN} -u "https://download.maxmind.com/geoip/databases/GeoLite2-ASN/download?suffix=tar.gz" -p "/usr/share/geoip" -d 0 -n "GeoLite2-ASN.mmdb" -f \
    && /tmp/install-release.sh -a ${MAXMIND_USER}:${MAXMIND_TOKEN} -u "https://download.maxmind.com/geoip/databases/GeoLite2-City/download?suffix=tar.gz" -p "/usr/share/geoip" -d 0 -n "GeoLite2-City.mmdb" -f \
    && /tmp/install-release.sh -a ${MAXMIND_USER}:${MAXMIND_TOKEN} -u "https://download.maxmind.com/geoip/databases/GeoLite2-Country/download?suffix=tar.gz" -p "/usr/share/geoip" -d 0 -n "GeoLite2-Country.mmdb" -f \
    && apt-get install -y gcc make gettext \
    && pushd /tmp/lua \
    && make install \
    && popd \
    && pushd /tmp/luarocks \
    && make install \
    && popd \
    && pushd /tmp/openresty \
    && make install \
    && popd \
    && useradd -s /usr/sbin/nologin nginx \
    && mkdir -p "${NGINX_CONF}" "${NGINX_LOG}" "${NGINX_CACHE}" "${CROWDSEC_DATA}" "${ACME_HOME}" "${ACME_CONFIG_HOME}" "${CERT_HOME}" \
    && /tmp/install-release.sh -r "crowdsecurity/cs-openresty-bouncer" -t "${CROWDSEC_VERSION}" -p /tmp/crowdsec -d 0 \
    && pushd /tmp/crowdsec \
    && ./install.sh --docker --LIB_PATH="${LUALIB}" --NGINX_CONF_DIR="${NGINX_CONF}" --CONFIG_PATH="${CROWDSEC_DATA}" --DATA_PATH="${CROWDSEC_DATA}" \
    && sed -i 's|ENABLED=.*|ENABLED=false|' "${CROWDSEC_DATA}"/crowdsec-openresty-bouncer.conf \
    && sed -i 's|MODE=.*|MODE=stream|' "${CROWDSEC_DATA}"/crowdsec-openresty-bouncer.conf \
    && popd \
    && /tmp/install-release.sh -r "acmesh-official/acme.sh" -t "${ACME_VERSION}" -k tarball -p /tmp/acme -o acme.tar.gz -d 0 \
    && pushd /tmp/acme \
    && ./acme.sh --install --no-profile --force --home "${ACME_HOME}" --config-home "${ACME_CONFIG_HOME}" --cert-home "${CERT_HOME}" \
    && popd \
    && acme.sh --set-default-ca --server letsencrypt \
    && apt-get remove -y gcc make gettext \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /etc/nginx \
    && rm -rf /tmp/* /var/cache/* /var/log/* /var/lib/apt/lists/* /var/lib/dpkg/status-old

WORKDIR /data
VOLUME [ "/data" ]

ENTRYPOINT [ "tini", "--" ]
CMD ["bash", "-c", "service cron start && nginx -g 'daemon off;'"]
