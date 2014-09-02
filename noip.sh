#!/bin/bash

if [ ! -f /config/noip2.conf ]; then
  echo "Could not find /config/noip2.conf"
  exit 1
fi

/root/noip2 -c /config/noip2.conf

# Since the above launches in the background...
while true
do
  sleep 3600
done
