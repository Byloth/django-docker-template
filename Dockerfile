FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND="noninteractive"
RUN apt-get update \
 && apt-get install --no-install-recommends \
                    --yes \
        \
        ca-certificates \
        curl \
        python3 \
 \
 && rm -rf /var/lib/apt/lists/*

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
                   --only main \
 \
 && rm -rf /root/.cache

FROM ubuntu:22.04 AS runner

ENV DEBIAN_FRONTEND="noninteractive"

ARG TIMEZONE="Etc/UTC"
ENV TZ="${TIMEZONE}"
RUN apt-get update \
 && apt-get install --no-install-recommends \
                    --yes \
        \
        tzdata \
 \
 && ln -snf "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime \
 && echo "${TIMEZONE}" > /etc/timezone \
 && dpkg-reconfigure --frontend "noninteractive" \
        tzdata \
 \
 && apt-get install --no-install-recommends \
                    --yes \
        \
        gosu \
        postgresql-client \
        python3 \
        uwsgi \
        uwsgi-plugin-python3 \
        wait-for-it \
 \
 && ln -s /usr/bin/python3 /usr/local/bin/python \
 && rm -rf /var/lib/apt/lists/*

RUN useradd --comment "Happy" \
            --no-create-home \
            --user-group happy

COPY --from=builder /usr/local/lib/python3.10/dist-packages /usr/local/lib/python3.10/dist-packages

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
CMD ["uwsgi"]

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
