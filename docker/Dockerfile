# TasmoAdmin Docker

# docker build . -t tasmoadmin
# docker run --name tasmoadmin -e TASMOADMIN_LOGIN=0 -p 8080:80  -v $(pwd)/tasmoadmin:/data  tasmoadmin

ARG ARCH=arm32v6
FROM "${ARCH}/alpine:3.10" AS nginx

ARG VERSION=1.6.3
ARG MYVERSION=jose0
ARG TASMOADMIN_PKG_URL=https://github.com/reloxx13/TasmoAdmin/releases/download/v${VERSION}/tasmoadmin_v${VERSION}.tar.gz
ARG DATADIR=/data
ARG WWWDIR=/var/www/tasmoadmin
ARG PORT=80
ARG UID=1000
ARG GUID=1000
ARG TZ=Europe/Amsterdam
ARG ARCH

LABEL org.label-schema.description="TasmoAdmin Docker image based on Alpine for the Raspberry Pi."
LABEL org.label-schema.name="TasmoAdmin"
LABEL org.label-schema.version="${VERSION}-${MYVERSION}"
LABEL org.label-schema.usage="https://hub.docker.com/r/jriguera/rpi-tasmoadmin/README.md"
LABEL org.label-schema.url="https://hub.docker.com/r/jriguera/rpi-tasmoadmin"
LABEL org.label-schema.vcs-url="https://github.com/jriguera/docker-rpi-tasmoadmin"
LABEL maintainer="Jose Riguera <jriguera@gmail.com>"
LABEL architecture="${ARCH}"

ENV TASMOADMIN_DATA="${DATADIR}"
ENV TASMOADMIN_PORT="${PORT}"
ENV TASMOADMIN_WWW="${WWWDIR}"
ENV TASMOADMIN_AUTH_FILE="${DATADIR}/auth/users"
ENV TASMOADMIN_TLS_CRT="${DATADIR}/certs/tasmoadmin.crt"
ENV TASMOADMIN_TLS_KEY="${DATADIR}/certs/tasmoadmin.key"

ENV LANG=en_US.utf8
ENV LC_ALL=C.UTF-8

RUN set -xe                                                                 && \
    apk -U upgrade                                                          && \
    # User/group
    addgroup -g "${GUID}" -S nginx                                          && \
    adduser -h "${DATADIR}" -D -G nginx -s /sbin/nologin -u "${UID}" nginx  && \
    # Installing Alpine packages
    apk add --no-cache \
        supervisor \
        ca-certificates \
        pwgen \
        su-exec \
        tzdata \
        socat \
        net-tools \
        curl \
        bash \
        nginx \
        php7-curl \
        php7-fpm \
        php7-json \
        php7-session \
        php7-openssl \
        php7-zip \
        php7-zlib \
        php7 \
                                                                            && \
    # Timezone
    cp "/usr/share/zoneinfo/${TZ}" /etc/localtime                           && \
    echo "${TZ}" > /etc/timezone                                            && \
    # clean up
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /var/cache/distfiles/*        && \
    install -d -m 0750 -o nginx -g root /var/tmp/nginx                      && \
    rm -rf /etc/nginx/conf.d

# Configure nginx
COPY --chown=nginx:root etc/nginx /etc/nginx/

# Copy custom errors
COPY --chown=nginx:nginx www /var/www/

# Configure PHP-FPM
COPY --chown=nginx:nginx etc/php/fpm-pool.conf /etc/php7/php-fpm.d/zzz_default.conf
COPY --chown=nginx:nginx etc/php/php.ini /etc/php7/conf.d/zzz_default.ini
COPY --chown=nginx:nginx etc/php/blacklist.txt /etc/php7/blacklist.txt

# Configure supervisord
COPY etc/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Download and install tasmoadmin
RUN set -xe                                                                 && \
    curl -fsSL -o /tmp/tasmoadmin.tgz ${TASMOADMIN_PKG_URL}                 && \
    mkdir -p ${WWWDIR}                                                      && \
    tar xf /tmp/tasmoadmin.tgz -C ${WWWDIR} --strip-components 1            && \
    rm -f /tmp/tasmoadmin.tgz                                               && \
    rm -fr ${WWWDIR}/data                                                   && \
    mkdir -p "${DATADIR}"                                                   && \
    ln -sf "${DATADIR}" "${WWWDIR}/data"                                    && \
    chown -R nginx:nginx "${DATADIR}" "${WWWDIR}"

COPY tasmoadmin.sh /usr/local/bin/
RUN set -xe                                                                 && \
    chmod a+x /usr/local/bin/*                                              && \
    ln -s /usr/local/bin/tasmoadmin.sh /usr/local/bin/docker-entrypoint.sh  && \
    ln -s /usr/local/bin/tasmoadmin.sh /docker-entrypoint.sh                && \
    ln -s /usr/local/bin/tasmoadmin.sh /run.sh

VOLUME ["${DATADIR}"]
EXPOSE "${PORT}"

# Define default command
CMD ["/run.sh"]

