FROM phusion/baseimage:0.9.17

MAINTAINER David Coppit <david@coppit.org>

VOLUME ["/config"]

# Add dynamic dns script
ADD noip.sh /root/noip/noip.sh
RUN chmod +x /root/noip/noip.sh

# Create template config file
ADD noip.conf /root/noip/noip.conf

CMD /root/noip/noip.sh
