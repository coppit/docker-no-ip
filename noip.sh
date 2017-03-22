#!/bin/bash

SOURCE_CONF=/config/noip.conf
GENERATED_CONF=/config/no-ip2.generated.conf

# Search for custom config file, if it doesn't exist, copy the default one
if [ ! -f "$SOURCE_CONF" ]; then
  echo "Creating config file. Please do not forget to enter your info in noip.conf."
  cp /files/noip.conf "$SOURCE_CONF"
  chmod a+w "$SOURCE_CONF"
  exit 1
fi

tr -d '\r' < "$SOURCE_CONF" > /tmp/noip.conf

. /tmp/noip.conf

if [ -z "$DOMAINS" ]; then
  echo "DOMAINS must be defined in noip.conf"
  exit 1
elif [ "$DOMAINS" = "foo.ddns.net" ]; then
  echo "Please enter your domain/group list in noip.conf"
  exit 1
fi

if [ -z "$USERNAME" ]; then
  echo "USERNAME must be defined in noip.conf"
  exit 1
elif [ "$USERNAME" = 'email@example.com' ]; then
  echo "Please enter your username in noip.conf"
  exit 1
fi

if [ -z "$PASSWORD" ]; then
  echo "PASSWORD must be defined in noip.conf"
  exit 1
elif [ "$PASSWORD" = "your password here" ]; then
  echo "Please enter your password in noip.conf"
  exit 1
fi

if [ -z "$INTERVAL" ]; then
  INTERVAL='30m'
fi

if [[ ! "$INTERVAL" =~ ^[0-9]+[mhd]$ ]]; then
  echo "INTERVAL must be a number followed by m, h, or d. Example: 5m"
  exit 1
fi

if [[ "${INTERVAL: -1}" == 'm' && "${INTERVAL%?}" -lt 5 ]]; then
  echo "The shortest allowed INTERVAL is 5 minutes"
  exit 1
fi

#-----------------------------------------------------------------------------------------------------------------------

function ts {
  echo [`date '+%b %d %X'`]
}

#-----------------------------------------------------------------------------------------------------------------------

# Convert to minutes
if [[ "${INTERVAL: -1}" == 'h' ]]; then
  INTERVAL=$(( ${INTERVAL%?}*60 ))
elif [[ "${INTERVAL: -1}" == 'd' ]]; then
  INTERVAL=$(( ${INTERVAL%?}*60*24 ))
fi

# Create the binary configuration file used by noip2.
# This comparison also works if $GENERATED_CONF is missing
if [[ "$SOURCE_CONF" -nt "$GENERATED_CONF" ]]; then
  expect /files/create_config.exp "$USERNAME" "$PASSWORD" "$DOMAINS" "$INTERVAL"
else
  echo "$(ts) $GENERATED_CONF is older than $SOURCE_CONF, so not regenerating it"
fi

while true
do
  echo "$(ts) Launching the noip2 daemon"
  /files/noip2-x86_64 -c "$GENERATED_CONF"

  # Give it a few seconds to do the first update. This helps avoid questions about "Last IP Address set 0.0.0.0"
  sleep 5

  while true
  do
    output=$(/files/noip2-x86_64 -c "$GENERATED_CONF" -S 2>&1)

    echo "$(ts) Current status"
    echo "$output"

    if [[ "$output" != *"started as"* ]]; then
      echo "$(ts) ERROR: noip2 daemon has stopped running. Restarting it in 60 seconds."
      sleep 60
      break
    fi

    sleep 60
  done
done
