#############
# Nginx Builder
#############

FROM debian:bookworm-slim

SHELL ["/bin/bash", "-eo", "pipefail", "-c"]

ARG OPENRESTY_VERSION=1.25.3.2
ARG RTMP_VERSION=1.2.2
ARG LUAROCKS_VERSION=3.11.1
ARG HTTP_PROXY=
ARG ALL_PROXY=
ARG NO_PROXY=
ENV HTTPS_PROXY=${HTTP_PROXY}
ENV HTTP_PROXY=${HTTP_PROXY}
ENV ALL_PROXY=${ALL_PROXY}
ENV NO_PROXY=${NO_PROXY}

COPY build /build/

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
    ca-certificates \
    curl \
    micro \
    unzip \
    xz-utils \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    libpcre3-dev \
    lua5.1 \
    liblua5.1-0-dev \
    libreadline-dev \
    libmaxminddb-dev \
    libmodsecurity-dev \
    && mv /build/scripts/install-release.sh /tmp/ \
    && ./tmp/install-release.sh -u "https://luarocks.github.io/luarocks/releases/luarocks-${LUAROCKS_VERSION}.tar.gz" -d 0 -p /tmp/luarocks \
    && ./tmp/install-release.sh -u "https://openresty.org/download/openresty-${OPENRESTY_VERSION}.tar.gz" -d 0 -p /tmp/openresty \
    && ./tmp/install-release.sh -r leev/ngx_http_geoip2_module -k 'tarball' -o http_geoip2.tar.gz -d 0 -p /tmp/openresty/ngx_http_geoip2_module \
    && ./tmp/install-release.sh -u "https://github.com/arut/nginx-rtmp-module/archive/refs/tags/v${RTMP_VERSION}.tar.gz" -d 0 -p /tmp/openresty/nginx-rtmp-module \
    && ./tmp/install-release.sh -r owasp-modsecurity/ModSecurity-nginx -m 'gz"$' -d 0 -p /tmp/openresty/ModSecurity-nginx \
    && pushd /tmp/luarocks \
    && ./configure \
    && make \
    && popd \
    && pushd /tmp/openresty \
    && ./configure \
    --prefix=/opt/openresty \
    --sbin-path=/usr/sbin/nginx \
    --modules-path=/usr/lib/nginx/modules \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/data/openresty/log/error.log \
    --http-log-path=/data/openresty/log/access.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --http-client-body-temp-path=/data/openresty/cache/client_temp \
    --http-proxy-temp-path=/data/openresty/cache/proxy_temp \
    --http-fastcgi-temp-path=/data/openresty/cache/fastcgi_temp \
    --http-uwsgi-temp-path=/data/openresty/cache/uwsgi_temp \
    --http-scgi-temp-path=/data/openresty/cache/scgi_temp \
    --user=nginx \
    --group=nginx \
    --with-compat \
    --with-threads \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_v3_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_sub_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_auth_request_module \
    --with-http_random_index_module \
    --with-http_secure_link_module \
    --with-http_slice_module \
    --with-http_stub_status_module \
    --with-mail \
    --with-mail_ssl_module \
    --with-stream \
    --with-stream_ssl_module \
    --with-stream_realip_module \
    --with-stream_ssl_preread_module \
    --add-module=./ngx_http_geoip2_module \
    --add-module=./nginx-rtmp-module \
    --add-module=./ModSecurity-nginx \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && popd \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /build /var/cache/* /var/log/* /var/lib/apt/lists/* /var/lib/dpkg/status-old

