#!/bin/bash

GENERATED_CONFIG_FILE=/config/no-ip2.generated.conf

#-----------------------------------------------------------------------------------------------------------------------

function ts {
  echo [`date '+%b %d %X'`]
}

#-----------------------------------------------------------------------------------------------------------------------

while true
do
  echo "$(ts) Launching the noip2 daemon"
  if [[ -z $(uname -a | grep "arm") ]]
  then
    /files/noip2-x86_64 -c "$GENERATED_CONFIG_FILE"
  else
    /usr/local/bin/noip2
  fi

  # Give it a few seconds to do the first update. This helps avoid questions about "Last IP Address set 0.0.0.0"
  sleep 5

  while true
  do
    if [[ -z $(uname -a | grep "arm") ]]
    then
      output=$(/files/noip2-x86_64 -c "$GENERATED_CONFIG_FILE" -S 2>&1)
    else
      output=$(/usr/local/bin/noip2 -S 2>&1)
    fi

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
