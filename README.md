# Docker tools

Scripts to remove and add all running docker containers in your `/etc/hosts` file.

## Add to your PHP project

```bash
composer require kba-team/dockertools --dev
```

## Add entries to hosts

In a bridged docker network, remove and add the IP addresses and hostnames of containers created by `docker-compose` in the `/etc/hosts` file. This will save you the hassle of port-forwarding, name resolvers, etc.

The script first removes all existing entries of all the hostnames of containers created by `docker-compose` in the `/etc/hosts` file and then adds them. This ensures, that there a no duplicate entries in the `/etc/hosts` file.

It is implied, that this script can only be called while docker containers are running. 

Usage: `add_docker_hosts.sh [-h] [-f <hosts-file>] [-r]`

* `-h` Display usage information.
* `-f <hosts-file>` Use a different hosts file than `/etc/hosts`.
* `-r` Only remove all the hostnames of containers created by `docker-compose`, but do not add them.

Examples:

* `vendor/bin/add_docker_hosts.sh`: Remove and then add all docker containers in the `/etc/hosts` file. 
* `vendor/bin/add_docker_hosts.sh -r`: Just remove all docker containers from the `/etc/hosts` file.

## Remove entries from hosts

Manually remove the given host names from the `/etc/hosts` file. Instead of host names, you can also use regular expressions.

Usage: `remove_docker_hosts.sh [-h] [-f <hosts-file>] <host-name> [<host-name> [...]]`

* `-h` Display usage information.
* `-f <hosts-file>` Use a different hosts file than `/etc/hosts`.

Example: `vendor/bin/remove_docker_hosts.sh "(unit1|unit2|unit3)(\\-test|)\\.test" "project-(db|selenium|mail)\\.test"`

## Environment variables

* `DOCKER_REGISTRY` Instead of using `busybox:latest` to manipulate the hosts file, `${DOCKER_REGISTRY}/busybox` will be used. This is useful, in case you manually cache docker images in a local registry for faster access.
