FROM phusion/baseimage:0.9.19

MAINTAINER David Coppit <david@coppit.org>

ENV DEBIAN_FRONTEND noninteractive

# Speed up APT
RUN echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup \
  && echo "Acquire::http {No-Cache=True;};" > /etc/apt/apt.conf.d/no-cache

VOLUME ["/config"]

# Add dynamic dns script
ADD noip.sh /root/noip/noip.sh
RUN chmod +x /root/noip/noip.sh

# Create template config file
ADD noip.conf /root/noip/noip.conf

CMD /root/noip/noip.sh
