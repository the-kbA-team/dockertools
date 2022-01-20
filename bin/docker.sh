#!/usr/bin/env sh

set -e

# display error message on STDERR
# @param string 1 error message
echo_error() {
  (>&2 echo "ERROR: $*")
}

# Echo command
# @param string 1 command string
echo_command() {
    # shellcheck disable=SC2086
    echo "==> $*"
}

# Canonicalize by following every symlink of the given name recursively
# @param string 1 The file path to canonicalize.
canonicalize() {
	NAME="$1"
	if [ -f "$NAME" ]
	then
		DIR=$(dirname -- "$NAME")
		NAME=$(cd -P "$DIR" > /dev/null && pwd -P)/$(basename -- "$NAME")
	fi
	while [ -h "$NAME" ]; do
		DIR=$(dirname -- "$NAME")
		SYM=$(readlink "$NAME")
		NAME=$(cd "$DIR" > /dev/null && cd "$(dirname -- "$SYM")" > /dev/null && pwd)/$(basename -- "$SYM")
	done
	echo "$NAME"
}

# Get the repository root directory.
get_repository_root() {
  git rev-parse --show-toplevel 2> /dev/null
  E=$?
  if [ ${E} -ne 0 ]; then
      echo_error "ERROR while trying to get the repository root!"
  fi
  return ${E}
}

# check if docker and docker-compose are installed
if ! type docker > /dev/null 2>&1; then (>&2 echo "ERROR: This tool needs docker do be installed!"); exit 2; fi
if ! type docker-compose > /dev/null 2>&1; then (>&2 echo "ERROR: This tool needs docker-compose do be installed!"); exit 2; fi
if ! type git > /dev/null 2>&1; then (>&2 echo "ERROR: This tool needs git do be installed!"); exit 2; fi

# Get the canonical path of this script
SELF=$(canonicalize "$0")
# Use this scripts canonical path for the hosts script too.
DOCKER_HOSTS="$(dirname -- "${SELF}")/docker_hosts.sh"
# Get the root path of the repository.
ROOT_DIR=$(get_repository_root)

if [ ! -f "${ROOT_DIR}/.env" ]; then
    echo_error "Configuration file '${ROOT_DIR}/.env' not found!"
    exit 1
fi

# Load configuration
# shellcheck disable=SC1091
. "${ROOT_DIR}/.env"

# Set defaults
DEFAULT_EXEC_USER="${DEFAULT_EXEC_USER:-www-data:www-data}"
DEFAULT_CONTAINER="${DEFAULT_CONTAINER:-web}"

# Display usage information
show_usage() {
    echo "Usage: docker.sh [command]"
}

# Display command list
show_commands() {
    echo
    echo "Available commands are:"
    echo " add-hosts      Add container hostnames and IPs to hosts file."
    echo " remove-hosts   Remove container hostnames and IPs from hosts file."
    echo " exec           Execute command(s) in docker container as '${DEFAULT_EXEC_USER}'."
    echo "                Available options:"
    echo "                  -u | --user             Run commands using user ID '$(id -u)' and group ID '$(id -g)'."
    echo "                  -c | --container [name] Run commands in the specified container. Default container: ${DEFAULT_CONTAINER}"
    echo " migrate        Run the migrations command '${MIGRATE_COMMAND}' inside the default container '${DEFAULT_CONTAINER}'."
    echo " seed           Run the seed command '${SEED_COMMAND}' inside the default container '${DEFAULT_CONTAINER}'."
    echo " start          Try to pull the current versions of the images, start the containers and add hostnames and IPs to the hosts file."
    echo " up             Run start, migrate and seed commands."
    echo " stop           Remove container hostnames and IPs from hosts file and stop the docker containers without destroying them."
    echo " down           Remove container hostnames and IPs from hosts file and destroy the docker containers."
    echo " restart        Run down and up commands."
    echo " cleanup        Delete files owned by '${DEFAULT_EXEC_USER}'."
    echo "                Available options:"
    echo "                  --root Delete files owned by 'root'."
    echo " behat          Run behat tests. Any additional parameters will be added to the behat command."
    echo " phpunit        Run phpunit tests. Any additional parameters will be added to the phpunit command."
    echo " help           Show this help."
}

while [ "${1}" ]; do
    COMMAND="${1}"
    shift
    case "${COMMAND}" in
        "add-hosts")
            echo_command "${DOCKER_HOSTS}"
            "${DOCKER_HOSTS}"
            ;;
        "remove-hosts")
            echo_command "${DOCKER_HOSTS} -r"
            "${DOCKER_HOSTS}" -r
            ;;
        "exec")
            if [ "${1}" = "--user" ] || [ "${1}" = "-u" ]; then
                shift
                EXEC_USER="$(id -u):$(id -g)"
            else
                EXEC_USER="${DEFAULT_EXEC_USER}"
            fi
            if [ "${1}" = "--container" ] || [ "${1}" = "-c" ]; then
                shift
                CONTAINER="${1}"
                shift
            else
                CONTAINER="${DEFAULT_CONTAINER}"
            fi
            echo_command "docker exec -tu ${EXEC_USER} ${CONTAINER} $*"
            [ -n "${CONTAINER}" ] && \
            docker exec -tu "${EXEC_USER}" "${CONTAINER}" "${@}"
            exit $?
            ;;
        "seed")
            if [ -n "${SEED_COMMAND}" ]; then
                "${SELF}" exec sh -c "${SEED_COMMAND}"
            fi
            ;;
        "migrate")
            if [ -n "${MIGRATE_COMMAND}" ]; then
                "${SELF}" exec sh -c "${MIGRATE_COMMAND}"
            fi
            ;;
        "start")
            # Ignore failures while pulling docker images
            echo_command "docker-compose pull"
            docker-compose pull || :
            echo_command "docker-compose up -d"
            docker-compose up -d
            "${SELF}" add-hosts
            ;;
        "up")
            "${SELF}" start migrate seed
            ;;
        "stop")
            "${SELF}" remove-hosts
            echo_command "docker-compose stop"
            docker-compose stop
            ;;
        "down")
            "${SELF}" remove-hosts
            echo_command "docker-compose down -v"
            docker-compose down -v
            # -v Remove named volumes declared in the volumes section of the
            # compose file and anonymous volumes attached to containers.
            ;;
        "restart")
            "${SELF}" down
            echo_command "sleep 1"
            sleep 1
            "${SELF}" up
            ;;
        "cleanup")
            if [ "${1}" = "--root" ]; then
                shift
                FIND_USER="root"
            else
                FIND_USER="${DEFAULT_EXEC_USER%%:*}"
            fi
            BUSYBOX="${BUSYBOX:-busybox:latest}"
            [ -z "${DOCKER_REGISTRY}" ] || BUSYBOX="${DOCKER_REGISTRY}/${BUSYBOX}"
            echo_command "docker pull ${BUSYBOX}"
            docker pull "${BUSYBOX}"
            echo_command "docker run --rm --init --tty --env FIND_USER=${FIND_USER} --volume ${ROOT_DIR}:/app --workdir /app ${BUSYBOX} find . -user ${FIND_USER} -delete"
            docker run \
                --rm \
                --init \
                --tty \
                --volume "${ROOT_DIR}":/app \
                --workdir /app \
                "${BUSYBOX}" \
                    find . -user "${FIND_USER}" -delete
            ;;
        "behat")
            if [ -f "${ROOT_DIR}/${BEHAT_BIN}" ]; then
                # shellcheck disable=SC2068
                "${SELF}" exec "${BEHAT_BIN}" ${@}
                exit $?
            fi
            exit 0
            ;;
        "phpunit")
            if [ -f "${ROOT_DIR}/${PHPUNIT_BIN}" ]; then
                # shellcheck disable=SC2068
                "${SELF}" exec "${PHPUNIT_BIN}" ${@}
                exit $?
            fi
            exit 0
            ;;
        "help"|"-h"|"--help")
            show_usage
            show_commands
            exit 1
            ;;
        * )
            echo_error "Unknown command ${COMMAND}"
            show_commands
            exit 1
            ;;
    esac
done
exit $?
