#!/usr/bin/env sh

################################################################################
# Docker tools                                                                 #
# Remove host names from your hosts file.                                      #
#                                                                              #
# @author Gregor J.                                                            #
################################################################################

HOSTSFILE="/etc/hosts"
BUSYBOX="busybox:latest"

set -e

# display usage information
show_usage() {
    echo "Remove host names from ${HOSTSFILE}."
    echo "Usage: remove_docker_hosts.sh [-f <hosts-file>] <host-name> [<host-name> [...]]"
    echo "<host-name> may also be a regular expression."
}

# check if there is an environment variable that sets a different docker registry
if [ -n "${DOCKER_REGISTRY}" ]; then
    BUSYBOX="${DOCKER_REGISTRY}/${BUSYBOX}"
fi

# check if docker and docker-compose are installed
if ! type docker > /dev/null 2>&1; then (>&2 echo "ERROR: This tool needs docker do be installed!"); exit 2; fi

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
            docker run --rm --init -v "${HOSTSFILE}":/tmp/h -e CONTAINERHOST="${1}" "${BUSYBOX}" sh -c 'sed -E "/.*${CONTAINERHOST}/d" /tmp/h | awk "NF" > /tmp/g; cat /tmp/g > /tmp/h' || exit $?
            shift # parameter host-name
            ;;
    esac
done
