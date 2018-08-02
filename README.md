docker-no-ip
============

This is a simple Docker container for running the [No-IP2](http://www.noip.com/) dynamic DNS update script. It will keep
your domain.ddns.net DNS alias up-to-date as your home IP changes.

Usage
-----

This docker image is available as a [trusted build on the docker index](https://index.docker.io/u/coppit/no-ip/).

Run:

`sudo docker run --name=noip -d -v /etc/localtime:/etc/localtime -v /config/dir/path:/config coppit/no-ip`

To check the status, run `docker logs noip`.

Docker-compose:

`docker-compose up -d`

To check the status, run `docker-compose logs`.

When run for the first time, a file named noip.conf will be created in the config dir, and the container will exit. Edit
this file, adding your username (email), password, and domains. Then rerun the command.

On subsequent runs, a binary config file /config/dir/path/no-ip2.generated.conf will be generated. Please do not edit
this file, as it is used by the noip2 agent.

