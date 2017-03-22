FROM phusion/baseimage:0.9.19

MAINTAINER David Coppit <david@coppit.org>

ENV DEBIAN_FRONTEND noninteractive

# Speed up APT
RUN echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup \
  && echo "Acquire::http {No-Cache=True;};" > /etc/apt/apt.conf.d/no-cache

VOLUME ["/config"]

RUN set -x \
  && apt-get update \
  && apt-get --no-install-recommends install -y expect \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD https://www.noip.com/client/linux/noip-duc-linux.tar.gz /files/

RUN set -x \
  && chmod a+rwX /files \
  && tar -C /files -x -f /files/noip-duc-linux.tar.gz noip-2.1.9-1/binaries/noip2-x86_64 \
  && mv /files/noip-2.1.9-1/binaries/noip2-x86_64 /files \
  && rm -rf /files/noip-2.1.9-1 /files/noip-duc-linux.tar.gz

COPY ["noip.conf", "create_config.exp", "noip.sh", "/files/"]
RUN chmod +x /files/noip.sh

CMD /files/noip.sh
