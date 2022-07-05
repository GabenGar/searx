FROM alpine:3.15
ENTRYPOINT ["/sbin/tini","--","/usr/local/searx/dockerfiles/docker-entrypoint.sh"]
VOLUME /etc/searx
VOLUME /var/log/uwsgi

ARG SEARX_GID
ARG SEARX_UID

RUN addgroup -g ${SEARX_GID} searx && \
    adduser -u ${SEARX_UID} -D -h /usr/local/searx -s /bin/sh -G searx searx

ENV INSTANCE_NAME=searx \
    AUTOCOMPLETE= \
    BASE_URL= \
    MORTY_KEY= \
    MORTY_URL= \
    SEARX_SETTINGS_PATH=/etc/searx/settings.yml \
    UWSGI_SETTINGS_PATH=/etc/searx/uwsgi.ini

WORKDIR /usr/local/searx


COPY requirements.txt ./requirements.txt

RUN apk upgrade --no-cache \
 && apk add --no-cache -t build-dependencies \
    build-base \
    py3-setuptools \
    python3-dev \
    libffi-dev \
    libxslt-dev \
    libxml2-dev \
    openssl-dev \
    tar \
    git \
 && apk add --no-cache \
    ca-certificates \
    su-exec \
    python3 \
    py3-pip \
    libxml2 \
    libxslt \
    openssl \
    tini \
    uwsgi \
    uwsgi-python3 \
    brotli \
 && pip3 install --upgrade pip wheel setuptools \
 && pip3 install --no-cache -r requirements.txt \
 && apk del build-dependencies \
 && rm -rf /root/.cache

COPY searx ./searx
COPY dockerfiles ./dockerfiles

ARG TIMESTAMP_SETTINGS
ARG TIMESTAMP_UWSGI
ARG VERSION_GITCOMMIT

RUN /usr/bin/python3 -m compileall -q searx; \
    touch -c --date=@${TIMESTAMP_SETTINGS} searx/settings.yml; \
    touch -c --date=@${TIMESTAMP_UWSGI} dockerfiles/uwsgi.ini; \
    if [ ! -z $VERSION_GITCOMMIT ]; then\
      echo "VERSION_STRING = VERSION_STRING + \"-$VERSION_GITCOMMIT\"" >> /usr/local/searx/searx/version.py; \
    fi; \
    find /usr/local/searx/searx/static -a \( -name '*.html' -o -name '*.css' -o -name '*.js' \
    -o -name '*.svg' -o -name '*.ttf' -o -name '*.eot' \) \
    -type f -exec gzip -9 -k {} \+ -exec brotli --best {} \+
