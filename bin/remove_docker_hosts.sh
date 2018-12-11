#!/usr/bin/env bash

################################################################################
# Docker tools                                                                 #
# Remove host names from your hosts file.                                      #
#                                                                              #
# @author Gregor Joham <gregor.joham@knorr-bremse.com>                         #
################################################################################

HOSTSFILE="/etc/hosts"
ROOT_CONTAINER="busybox"

set -e

# display usage information
function show_usage() {
    echo "Remove host names from ${HOSTSFILE}."
    echo "Usage: remove_docker_hosts.sh [-f <hosts-file>] <host-name> [<host-name> [...]]"
    echo "<host-name> may also be a regular expression."
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
        * )
            docker run --rm --init -v "${HOSTSFILE}":/tmp/editfile -e CONTAINERHOST=${1} ${ROOT_CONTAINER} sh -c 'sed -E "/.*${CONTAINERHOST}/d" /tmp/editfile | awk "NF" > /tmp/editfile.tmp; cat /tmp/editfile.tmp > /tmp/editfile; rm -f /tmp/editfile.tmp' || exit $?
            shift # parameter host-name
            ;;
    esac
done
