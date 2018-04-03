#!/usr/bin/env bash

################################################################################
# Docker tools                                                                 #
# Determine the IP address of a given docker container.                        #
#                                                                              #
# @author Gregor Joham <gregor.joham@knorr-bremse.com>                         #
################################################################################

set -e

# display usage information
function show_usage() {
    echo "Usage: container_ip.sh <container-name> [<container-name> [...]]"
}

# check parameters
if [ -z "${1}" ]; then (>&2 echo "ERROR: container name missing!"); show_usage; exit 1; fi

# display usage on help parameter
case "${1}" in
    -h | --help )
        show_usage
        exit 1
        ;;
esac

# Loop through the rest of the parameters and assume that they are container names.
while [ "${1}" ]; do
    echo -n "${1} "
    docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "${1}" || exit $?
    shift
done
