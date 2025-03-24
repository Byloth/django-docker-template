FROM alpine:3.21 AS builder

RUN apk add --no-cache \
        curl \
        gcc \
        musl-dev \
        postgresql-dev \
        python3-dev \
        py3-pip

ENV POETRY_HOME="/opt/poetry"
ENV POETRY_VIRTUALENVS_CREATE="false"
RUN curl -sSL "https://install.python-poetry.org" | \
        python3 - --yes \
 \
 && ln -s "${POETRY_HOME}/bin/poetry" /usr/local/bin/poetry \
 \
 && rm -rf /root/.cache \
           /root/.local

WORKDIR "/etc/happy"
COPY pyproject.toml ./
COPY poetry.lock ./

RUN poetry install --no-ansi \
                   --no-cache \
                   --no-root \
                   --with prod \
 \
 && rm -rf /root/.cache

FROM alpine:3.21 AS runner

ARG LANGUAGE="C.UTF-8"
ENV LANG="${LANGUAGE}"
ENV LANGUAGE="${LANGUAGE}"
ENV LC_ALL="${LANGUAGE}"

ARG TIMEZONE="Etc/UTC"
ENV TZ="${TIMEZONE}"

RUN apk add --no-cache \
        bash \
        postgresql-client \
        python3 \
        su-exec \
        tzdata \
 \
 && ln -s /usr/bin/python3 /usr/local/bin/python3

RUN adduser -h /var/www \
            -s /bin/bash \
            -u 82 \
            -G www-data \
            -D \
        \
        www-data

COPY --from=builder /usr/lib/python3.12/site-packages /usr/lib/python3.12/site-packages
COPY --from=builder /usr/bin/uvicorn /usr/local/bin/uvicorn

WORKDIR "/opt/happy"
COPY src/ ./

RUN python -m compileall .

ENV DATA_VOLUME="/var/lib/happy"
ENV DEBUG=""
ENV SECRET_KEY=""

ENV PGHOST="host.docker.internal"
ENV PGPORT="5432"
ENV PGUSER="happy"
ENV PGPASSWORD=""
ENV PGDATABASE="happy"

ENTRYPOINT ["./entrypoint.sh"]
CMD ["uvicorn"]

EXPOSE 8000
VOLUME ["${DATA_VOLUME}"]

ARG VERSION
ARG COMMIT_SHA
ARG CREATE_DATE

LABEL org.opencontainers.image.title="Happy"
LABEL org.opencontainers.image.description="A template of a ready-to-use dockerized Django application."
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL org.opencontainers.image.revision="${COMMIT_SHA}"
LABEL org.opencontainers.image.source="https://github.com/Byloth/django-docker-template"
LABEL org.opencontainers.image.url="https://github.com/Byloth/django-docker-template"
LABEL org.opencontainers.image.authors="Matteo Bilotta <me@byloth.dev>"
LABEL org.opencontainers.image.vendor="Bylothink"
LABEL org.opencontainers.image.created="${CREATE_DATE}"
