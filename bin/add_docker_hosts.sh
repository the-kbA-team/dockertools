#!/usr/bin/env bash

################################################################################
# Docker tools                                                                 #
# Add IPs of docker containers to your hosts file.                             #
#                                                                              #
# @author Gregor Joham <gregor.joham@knorr-bremse.com>                         #
################################################################################

HOSTSFILE="/etc/hosts"
CONTAINERIP=""
ROOT_CONTAINER="busybox"

set -e

# display usage information
function show_usage() {
    echo "Usage: add_docker_hosts.sh [-f <hosts-file>] -c <container-name> <host-name> [<host-name> [...]]"
}

# determine whether a container is up
function is_container_up() {
    CONTAINERUPREGEX=".*[[:space:]]Up[[:space:]].*[[:space:]]${1}\$"
    docker ps | grep -E "${CONTAINERUPREGEX}" &> /dev/null
    return $?
}

# check if there is an environment variable that sets a different docker registry
if [ -n "${DOCKER_REGISTRY}" ]; then
    ROOT_CONTAINER="${DOCKER_REGISTRY}/${ROOT_CONTAINER}"
fi

# check if docker is installed
if [ -z $(which docker) ]; then (>&2 echo "ERROR: This tool needs docker do be installed!"); exit 2; fi

# check parameters
if [ -z "${1}" ]; then (>&2 echo "ERROR: parameters missing!"); show_usage; exit 1; fi

# loop through the parameters
while [ "${1}" ]; do
    case "${1}" in
        -h | --help )
            show_usage
            exit 1
            ;;
        -f | --file )
            shift # parameter -f
            if [ -z "${1}" ]; then (>&2 echo "ERROR: hosts-file missing!"); show_usage; exit 1; fi
            if [ ! -f "${1}" ]; then (>&2 echo "ERROR: hosts-file \"${1}\" does not exist!"); exit 1; fi
            HOSTSFILE="${1}"
            shift # parameter hosts-file
            ;;
        -c | --container )
            shift # parameter -c
            if [ -z "${1}" ]; then (>&2 echo "ERROR: container-name missing!"); show_usage; exit 1; fi
            if ! is_container_up "${1}"; then (>&2 echo "ERROR: container ${1} not running!"); show_usage; exit 1; fi
            CONTAINERIP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "${1}") || exit $?
            shift # parameter container-name
            ;;
        * )
            if [ -z "${CONTAINERIP}" ]; then (>&2 echo "ERROR: container-name missing!"); show_usage; exit 1; fi
            docker run --rm --init -v "${HOSTSFILE}":/tmp/editfile -e CONTAINERIP=${CONTAINERIP} -e CONTAINERHOST=${1} ${ROOT_CONTAINER} sh -c 'echo "${CONTAINERIP} ${CONTAINERHOST}" | tee -a /tmp/editfile' || exit $?
            shift # parameter host-name
            ;;
    esac
done
