#!/usr/bin/env bash

################################################################################
# Docker tools                                                                 #
# Wait until a certain command inside a docker container succeeds.             #
#                                                                              #
# @author Gregor Joham <gregor.joham@knorr-bremse.com>                         #
################################################################################

set -e

# display usage information
function show_usage() {
    echo "Usage: wait_for_container.sh <container-name> \"<command that has to be successful>\""
}

# check parameters
if [ -z "${1}" ]; then (>&2 echo "ERROR: container name and command missing!"); show_usage; exit 1; fi
if [ -z "${2}" ]; then (>&2 echo "ERROR: container command missing!"); show_usage; exit 1; fi

# load possible environment variables
BASEDIR=$(pwd)
if [ -e "${BASEDIR}/.env" ]; then
    source "${BASEDIR}/.env";
fi

# assign parameters to variables to be more readable
CONTAINERNAME="${1}"
CONTAINERCMD="${2}"

# before running a command inside a container, test if the container is up
CONTAINERUPREGEX=".*[[:space:]]Up[[:space:]].*[[:space:]]${CONTAINERNAME}\$"
until (docker ps | grep -E "${CONTAINERUPREGEX}" &> /dev/null)
do
    echo "Waiting for container '${CONTAINERNAME}' ..."
    sleep 3
done
echo "Container '${CONTAINERNAME}' is up!"

# now connect to the container and run the given command
until (docker exec "${CONTAINERNAME}" bash -c "${CONTAINERCMD}" &> /dev/null)
do
    echo "Waiting for '${CONTAINERNAME}' to be ready ..."
    sleep 3
done
echo "Container '${CONTAINERNAME}' is ready!"
