#!/bin/bash

# Search for custom config file, if it doesn't exist, copy the default one
if [ ! -f /config/noip.conf ]; then
  echo "Creating config file. Please do not forget to enter your info in noip.conf."
  cp /root/noip/noip.conf /config/noip.conf
  chmod a+w /config/noip.conf
  exit 1
fi

tr -d '\r' < /config/noip.conf > /tmp/noip.conf

. /tmp/noip.conf

if [ -z "$DOMAINS" ]; then
  echo "DOMAINS must be defined in noip.conf"
  exit 1
elif [ "$DOMAINS" = "foo.ddns.net" ]; then
  echo "Please enter your domain in noip.conf"
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

USER_AGENT="coppit docker no-ip/.1 $USERNAME"

#-----------------------------------------------------------------------------------------------------------------------

function ts {
  echo [`date '+%b %d %X'`]
}

#-----------------------------------------------------------------------------------------------------------------------

while true
do
  RESPONSE=$(curl -s -k --user-agent "$USER_AGENT" -u "$USERNAME:$PASSWORD" "https://dynupdate.no-ip.com/nic/update?hostname=$DOMAINS")

  SUCCESS_REGEX='^(good|nochg) '

  if [[ $RESPONSE =~ $SUCCESS_REGEX ]]
  then
    echo "$(ts) No-IP successfully called. Result was \"$RESPONSE\"."
  else
    echo "$(ts) Something went wrong. Check your settings. Result was \"$RESPONSE\"."
    echo "$(ts) For an explanation of error codes, see http://www.noip.com/integrate/response"
    exit 2
  fi

  sleep 300
done
