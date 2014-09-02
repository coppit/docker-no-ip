docker-no-ip
============

This is a simple Docker container for running the [No-IP](http://www.noip.com/) dynamic DNS update script. It will keep
your domain.ddns.net DNS alias up-to-date as your home IP changes.

Usage
-----

This docker image is available as a [trusted build on the docker index](https://index.docker.io/u/coppit/no-ip/).

To set up the configuration file, create /config/dir/path and then run this docker container interactively:

`docker run -i --name=no-ip -v /config/dir/path:/config -t coppit/no-ip /root/noip2 -c /config/noip2.conf -C`

Answer "N" to the question about running something after a successful update.

Once the config is set up, run the container this way:

`docker start no-ip`

This container is stateless. If you don't need it anymore, you can `stop` and `remove` it.
