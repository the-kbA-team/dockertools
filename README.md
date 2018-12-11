# Docker tools

Useful tools when you are running your project inside docker containers.

## Add entries to hosts

In a bridged docker network, add the IP address of a given container name to the `/etc/hosts` file using the given hostname(s). This will spare you the hassle of port forwardings, name resolvers, etc.

Usage: `add_docker_hosts.sh [-f <hosts-file>] -c <container-name> <host-name> [<host-name> [...]]`

Example: `add_docker_hosts.sh -c project-web unit1.test unit1-test.test unit3.test unit3-test.test unit2.test unit2-test.test -c project-db project-db.test -c project-selenium project-selenium.test -c project-mail project-mail.test`

## Remove entries from hosts

Remove given host names from the `/etc/hosts` file. Instead of host names, you can also use regular expressions.

Usage: `remove_docker_hosts.sh [-f <hosts-file>] <host-name> [<host-name> [...]]`

Example: `remove_docker_hosts.sh "(unit1|unit2|unit3)(\\-test|)\\.test" "project-(db|selenium|mail)\\.test"`

## Wait for containers to be ready

Waits for a container to come _up_ and then waits until a given command succeeds.

Usage: `wait_for_container.sh <container-name> "<command-to-succeed>"`

Example:
```
$ wait_for_container.sh project-db 'echo "select count(*) from ${DATABASE}.users;" | mysql -h localhost -u root -p"${ROOT_PASSWORD}" | grep -qE "^1"'
Container 'project-db' is up!
Waiting for 'project-db' to be ready ...
Waiting for 'project-db' to be ready ...
Waiting for 'project-db' to be ready ...
Waiting for 'project-db' to be ready ...
Container 'project-db' is ready!
```

## Get IP address of container

Usage: `container_ip.sh <container-name> [<container-name> [...]]`

Example: 
```bash
$ container_ip.sh project-web project-db project-selenium project-mail
project-web 172.18.0.5
project-db 172.18.0.4
project-selenium 172.18.0.3
project-mail 172.18.0.2
```

## Add to your PHP project

```bash
composer require kba-team/dockertools --dev
```

## Environment variables

* `DOCKER_REGISTRY` Instead of using `busybox` to manipulate the hosts file, `${DOCKER_REGISTRY}/busybox` will be used. This is useful, in case you manually cache docker images in a local registry for faster access.
