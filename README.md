docker-no-ip
============

This is a simple Docker container for running the [No-IP](http://www.noip.com/) dynamic DNS update script. It will keep
your domain.ddns.net DNS alias up-to-date as your home IP changes. The script runs every 5 minutes.

Usage
-----

This docker image is available as a [trusted build on the docker index](https://index.docker.io/u/coppit/no-ip/).

Run:

`sudo docker run --name=noip -d -v /etc/localtime:/etc/localtime -v /config/dir/path:/config coppit/no-ip`

When run for the first time, a file named noip.conf will be created in the config dir, and the container will exit. Edit
this file, adding your username (email), password, and domains. Then rerun the command.

To check the status, run `docker logs noip`.
