#!/usr/bin/env bash
#

set -e

HELP="
Runs the \"Happy\" application.

By default, it runs using Uvicorn ASGI web server.
For other run mode, please read the following command line options:

Usage:
    docker run ... [MODE] [OPTIONS]

Modes:
    init            Force the setup of the environment to run the application properly.
                    This command runs automatically when the application is
                     executed for the first time or following an update
                     so you usually don't need to run it manually.

                    Practically, it runs 'python manage.py collectstatic' and
                     changes the ownership of the \${DATA_VOLUME} to 'www-data:www-data'.

    -- | uvicorn    Runs the backend application using Uvicorn ASGI web server.
                    This is the default run mode.

    django          Runs the backend application using Django.
                    This is only for development purpose
                     and always runs in \${DEBUG} mode.

                    Practically, this mode runs 'python manage.py runserver'.
                    If you'll pass any other argument, it will be directly passed to
                     'manage.py' script, allowing you to run any available Django command.

                        e.g. 'docker run ... django createsuperuser' -> 'python manage.py createsuperuser'

    *               Any other value will be treated as a normal
                     command to execute inside the Docker container.

Options:
    --debug             Runs the backend application in \${DEBUG} mode.

    -h | -? | --help    Prints this help message."

VERSION="1.1.0"

#
# Functions:
#
function init-check()
{
    if [[ ! -f "${DATA_VOLUME}/.version" ]]
    then
        init-force
    fi

    local CURRENT_VERSION="$(cat "${DATA_VOLUME}/.version")"
    if [[ "${CURRENT_VERSION}" != "${VERSION}" ]]
    then
        init-force
    fi
}
function init-force()
{
    chown -R www-data:www-data "${DATA_VOLUME}"
    python manage.py collectstatic --noinput

    echo "${VERSION}" > "${DATA_VOLUME}/.version"
}

function run-django()
{
    export DEBUG="true"

    if [[ ${#} -eq 0 ]]
    then
        set -- "runserver" "0.0.0.0:8000"
    fi

    python manage.py ${@}
}
function run-uvicorn()
{
    local ARGS=()

    while [[ ${#} -gt 0 ]]
    do
        case "${1}" in
            --debug)
                export DEBUG="true"
                ;;
            *)
                ARGS+=("${1}")
                ;;
        esac

        shift
    done

    set -- "${ARGS[@]}"

    if [[ -n "${DEBUG}" ]]
    then
        local RELOAD="--reload"
    fi

    su-exec www-data uvicorn happy.asgi:application --host "0.0.0.0" \
                                                    --port 8000 \
                                                    \
                                                    ${RELOAD} ${@}
}

#
# Execution:
#
init-check

case "${1}" in
    -h | -? | --help)
        echo "${HELP}"
        ;;

    init)
        shift
        init-force ${@}

        ;;

    django)
        shift
        run-django ${@}

        ;;

    -- | uvicorn)
        shift
        run-uvicorn ${@}

        ;;
    -*)
        run-uvicorn ${@}

        ;;
    *)
        exec ${@}

        ;;
esac
