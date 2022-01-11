# Docker tools

[docker-compose] is a very useful tool, especially if you're programming inside a network of docker-containers. Accessing the (TCP) services of these docker containers, however is not so easy. To the best of my knowledge there are currently no tools available, that will add the IPs and hostnames of your running network to your hosts `/etc/hosts` file- until now.

## Why not use <insert DNS/discovery service here>?

Running a DNS service for docker containers always messes with the DNS settings of your workstation. Especially if these DNS/discovery services themselves run inside docker containers on an active development workstation. Resolving DNS issues is not an easy task. Contrary to that the `/etc/hosts` file is simple. It couldn't care less if your workstation switches domains, DNS services, VPNs, etc. on-the-fly. In case something goes wrong, you can always edit the file manually. _It was made for adding the hosts of a docker network_ (joke). I like the `/etc/hosts` file (not a joke).

## Add to your PHP project

```bash
composer require kba-team/dockertools --dev
```

## Add entries to hosts

In a bridged docker network, remove and add the IP addresses and hostnames of containers created by `docker-compose` in the `/etc/hosts` file. This will save you the hassle of port-forwarding, name resolvers, etc.

The script first removes all existing entries of all the hostnames of containers created by `docker-compose` in the `/etc/hosts` file and then adds them. This ensures, that there a no duplicate entries in the `/etc/hosts` file.

It is implied, that this script can only be called while docker containers are running. 

Usage: `docker_hosts.sh [-h] [-f <hosts-file>] [-r]`

* `-h` Display usage information.
* `-f <hosts-file>` Use a different hosts file than `/etc/hosts`.
* `-r` Only remove all the hostnames of containers created by `docker-compose`, but do not add them.

### Examples:

* `vendor/bin/docker_hosts.sh`: Remove and then add all docker containers in the `/etc/hosts` file. 
* `vendor/bin/docker_hosts.sh -r`: Just remove all docker containers from the `/etc/hosts` file.

### Environment variables

* `DOCKER_REGISTRY` Instead of using `busybox:latest` to manipulate the hosts file, `${DOCKER_REGISTRY}/busybox` will be used. This is useful, in case you manually cache docker images in a local registry for faster access.

## Automate docker-compose

In order to automate commands that need execution _after_ docker-compose did its work, use `bin/docker.sh`.

Usage: `vendor/bin/docker.sh <command>`

Available commands are:

 * `add-hosts` Add container hostnames and IPs to hosts file.
 * `remove-hosts` Remove container hostnames and IPs from hosts file.
 * `exec` Execute command(s) in docker container as `${DEFAULT_EXEC_USER:-www-data:www-data}`. Available options:
   * `-u` | `--user` Run commands using user ID `$(id -u)` and group ID `$(id -g)`.
   * `-c` | `--container <name>` Run commands in the specified container. Default container: `${DEFAULT_CONTAINER:-web}`
 * `migrate` Run the migrations command `${MIGRATE_COMMAND}` inside the default container `${DEFAULT_CONTAINER:-web}`.
 * `seed` Run the seed command `${MIGRATE_COMMAND}` inside the default container `${DEFAULT_CONTAINER:-web}`.
 * `start` Try to pull the current versions of the images, start the containers and add hostnames and IPs to the hosts file.
 * `up` Run start, migrate and seed commands.
 * `stop` Remove container hostnames and IPs from hosts file and stop the docker containers without destroying them.
 * `down` Remove container hostnames and IPs from hosts file and destroy the docker containers.
 * `restart` Run down and up commands.
 * `behat` Run behat tests. Any additional parameters will be added to the behat command.
 * `phpunit` Run phpunit tests. Any additional parameters will be added to the phpunit command.
 * `help` Show help.

### Environment variables

Configure the environment variables in your `.env` file. That way it can be used by docker-compose as well (DRY).

* `DEFAULT_EXEC_USER` The default user executing commands inside docker containers.
* `DEFAULT_CONTAINER` The default container to execute commands in.
* `MIGRATE_COMMAND` The command running the migrations to set up the DB structure. In case this variable is not defined, nothing happens.
* `SEED_COMMAND` The command adding seed data to your empty DB. In case this variable is not defined, nothing happens.
* `PHPUNIT_BIN` The path to the PHPunit binary. In case this variable is not defined, nothing happens.
* `BEHAT_BIN` The path to the Behat binary. In case this variable is not defined, nothing happens.

[docker-compose]:https://docs.docker.com/compose/
