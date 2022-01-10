#!/usr/bin/env sh

################################################################################
# Docker tools                                                                 #
# Add/remove IPs of docker containers to your hosts file.                      #
#                                                                              #
# @author Gregor J.                                                            #
################################################################################

HOSTSFILE="/etc/hosts"
BUSYBOX="busybox:latest"
HOSTS_FORMAT='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{range .Aliases}} {{.}}{{end}}{{printf "\n"}}{{end}}'

set -e

# display usage information
show_usage() {
    echo "Add the IPs and hostnames of all containers started by docker-compose to ${HOSTSFILE}."
    echo
    echo "Usage: docker_hosts.sh [-f <hosts-file>] [-r]"
}

# check if there is an environment variable that sets a different docker registry
if [ -n "${DOCKER_REGISTRY}" ]; then
    BUSYBOX="${DOCKER_REGISTRY}/${BUSYBOX}"
fi

# check if docker and docker-compose are installed
if ! type docker > /dev/null 2>&1; then (>&2 echo "ERROR: This tool needs docker do be installed!"); exit 2; fi
if ! type docker-compose > /dev/null 2>&1; then (>&2 echo "ERROR: This tool needs docker-compose do be installed!"); exit 2; fi

# loop through the options
while [ "${1}" ]; do
    case "${1}" in
        -h | --help )
            show_usage
            exit 1
            ;;
        -f | --file )
            shift # option -f
            if [ -z "${1}" ]; then (>&2 echo "ERROR: hosts-file missing!"); show_usage; exit 1; fi
            if [ ! -f "${1}" ]; then (>&2 echo "ERROR: hosts-file \"${1}\" does not exist!"); exit 1; fi
            HOSTSFILE="${1}"
            shift # option parameter hosts-file
            ;;
        -r | --rm )
            shift # option -r
            ADD_HOSTS=0
            ;;
        * )
            (>&2 echo "ERROR: Unknown option '${1}'.")
            exit 2
            ;;
    esac
done

# List all docker containers started by docker-compose
docker-compose ps -q | while read -r container; do
    # Remove all line(s) from the hosts file containing the hostname
    docker run --rm \
        -v "${HOSTSFILE}":/tmp/h \
        --env HOST_NAME="$(docker inspect --format "{{.Config.Hostname}}" "${container}")" \
        "${BUSYBOX}" sh -c 'echo "Removing ${HOST_NAME}"; sed -E "/.* ${HOST_NAME//\./\\.}/d" /tmp/h | awk "NF" > /tmp/g; cat /tmp/g > /tmp/h';
done

if [ "${ADD_HOSTS:-1}" = "1" ]; then
    echo "==> Adding hostnames:"

    # List all docker containers started by docker-compose
    docker-compose ps -q | while read -r container; do
        # Extract IP and hostnames from each container
        docker inspect --format "${HOSTS_FORMAT}" "${container}";
    # remove empty lines and append all lines to the hosts-file
    done | awk "NF" | docker run --rm -i -v "${HOSTSFILE}":/tmp/h "${BUSYBOX}" tee -a /tmp/h
fi
