#!/bin/sh

# Based on https://github.com/sanjeevan/baseimage

shutdown() {
  echo
  echo "Shutting down container..."

  # first shutdown any service started by runit
  for _srv in $(ls -1 /etc/service); do
    sv force-stop $_srv
  done

  # shutdown runsvdir command
  kill -HUP $RUNSVDIR
  wait $RUNSVDIR

  # give processes time to stop
  sleep 0.5

  # kill any other processes still running in the container
  for _pid  in $(ps -eo pid | grep -v PID  | tr -d ' ' | grep -v '^1$' | head -n -6); do
    timeout -t 5 /bin/sh -c "kill $_pid && wait $_pid || kill -9 $_pid"
  done

  exit
}

# catch shutdown signals
trap shutdown SIGTERM SIGHUP SIGQUIT SIGINT

# store environment variables
export > /etc/envvars

PATH=/bin:/sbin:/usr/bin

# run all scripts in the run_once folder
if ! /bin/run-parts /etc/run_once
then
  echo "Run-once scripts failed. Stopping container"
  shutdown
fi

exec env - PATH=$PATH runsvdir -P /etc/service &

RUNSVDIR=$!
echo "Started runsvdir, PID is $RUNSVDIR. Waiting for processes to start...."

sleep 5
for _srv in $(ls -1 /etc/service); do
    sv status $_srv
done

wait $RUNSVDIR

shutdown
