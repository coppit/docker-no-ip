#!/usr/bin/python3

import json
import logging
import os
import subprocess
import sys
import tempfile
import time

from shutil import copyfile

DEFAULT_CONF = '/files/noip.conf'
SOURCE_CONF = '/config/noip.conf'
GENERATED_CONF = '/config/no-ip2.generated.conf'

#-----------------------------------------------------------------------------------------------------------------------

def remove_linefeeds(input_filename):
    if not os.path.exists(input_filename): return None

    temp = tempfile.NamedTemporaryFile(delete=False)

    with open(input_filename, "r") as input_file:
        with open(temp.name, "w") as output_file:
            for line in input_file:
                output_file.write(line)

    return temp.name

#-----------------------------------------------------------------------------------------------------------------------

def merge_config_file_into_environment():
    config_file = remove_linefeeds(SOURCE_CONF)

    # Shenanigans to read docker env vars, and the bash format config file. I didn't want to ask them to change their
    # config files.
    dump_command = '/usr/bin/python3 -c "import os, json;print(json.dumps(dict(os.environ)))"'

    pipe = subprocess.Popen(['/bin/bash', '-c', dump_command], stdout=subprocess.PIPE)
    string = pipe.stdout.read().decode('ascii')
    base_env = json.loads(string)

    if config_file:
        source_command = 'source {}'.format(config_file)
        pipe = subprocess.Popen(['/bin/bash', '-c', 'set -a && {} && {}'.format(source_command,dump_command)],
            stdout=subprocess.PIPE)
        string = pipe.stdout.read().decode('ascii')
        config_env = json.loads(string)
    else:
        config_env = {}

    # ENV vars take precedence
    env = config_env.copy()
    env.update(base_env)

    return env

#-----------------------------------------------------------------------------------------------------------------------

def parse_vars(env):
    # Set defaults
    if 'INTERVAL' not in env:
        env['INTERVAL'] = '30m'

    if 'DEBUG' not in env:
        env['DEBUG'] = False

    # If neither a config file was provided, nor
    if 'USERNAME' not in env or 'PASSWORD' not in env or 'DOMAINS' not in env:
        if not os.path.exists(SOURCE_CONF):
            logging.info("Creating config file. Please do not forget to enter your info in noip.conf, or to pass it" \
                " using environment variables.")
            copyfile(DEFAULT_CONF, SOURCE_CONF)
            os.chmod(SOURCE_CONF, 0o666)
        else:
            logging.error("Could not get USERNAME, PASSWORD, DOMAINS, AND INTERVAL from config file or environment" \
                " variables.")

        sys.exit(1)

    if env['DOMAINS'] == 'foo.ddns.net' or env['USERNAME'] == 'email@example.com' or env['PASSWORD'] == 'your password here':
        logging.error("Found default values for USERNAME, PASSWORD, or DOMAINS. Please edit your noip.conf file.")
        sys.exit(1)

    if env['INTERVAL'][-1] not in ['m','h','d']:
        logging.error("INTERVAL must be a number followed by m, h, or d. Example: 5m")
        sys.exit(1)

    if env['INTERVAL'][-1] == 'm':
        env['INTERVAL'] = int(env['INTERVAL'][0:-1])
    elif env['INTERVAL'][-1] == 'h':
        env['INTERVAL'] = int(env['INTERVAL'][0:-1]) * 60
    elif env['INTERVAL'][-1] == 'd':
        env['INTERVAL'] = int(env['INTERVAL'][0:-1]) * 60 * 24

    if env['INTERVAL'] < 5:
        logging.error("The shortest allowed INTERVAL is 5 minutes")
        sys.exit(1)


    class Args:
        pass

    args = Args()

    args.domains = env['DOMAINS']
    args.username = env['USERNAME']
    args.password = env['PASSWORD']
    args.interval = env['INTERVAL']
    args.debug = env['DEBUG']

    logging.info("CONFIGURATION:")
    logging.info("  USERNAME=%s", args.username)
    logging.info("  PASSWORD=<hidden>")
    logging.info("   DOMAINS=%s", args.domains)
    logging.info("  INTERVAL=%s", args.interval)
    logging.info("     DEBUG=%s", args.interval)

    return args

#-----------------------------------------------------------------------------------------------------------------------

def create_binary_noip_conf_file(username, password, domains, interval):
    if os.path.exists(SOURCE_CONF) and os.path.exists(GENERATED_CONF):
        source_conf_time = os.path.getmtime(SOURCE_CONF)
        generated_conf_time = os.path.getmtime(GENERATED_CONF)

        if source_conf_time < generated_conf_time:
            logging.info("%s is older than %s, so not regenerating it", GENERATED_CONF, SOURCE_CONF)
            return

    returncode = subprocess.call(['expect', '/files/create_config.exp', username, password, domains, str(interval)])

    if returncode != 0:
        logging.error("Failed to create noip2 configuration file $GENERATED_CONF. Exiting")
        sys.exit(returncode)

#-----------------------------------------------------------------------------------------------------------------------

logging.basicConfig(level=logging.INFO, format='[%(asctime)s] %(message)s', datefmt='%Y-%m-%d %H:%M:%S')

env = merge_config_file_into_environment()
args = parse_vars(env)

#args.debug = True

if args.debug: logging.getLogger().setLevel(logging.DEBUG)

create_binary_noip_conf_file(args.username, args.password, args.domains, args.interval)

noip_command = ['/files/noip2-x86_64', '-c', GENERATED_CONF]

while True:
    logging.info("Launching the noip2 daemon")

    subprocess.check_call(noip_command)

    # Give it a few seconds to do the first update. This helps avoid questions about "Last IP Address set 0.0.0.0"
    time.sleep(5)

    while True:
        output = subprocess.check_output(noip_command + ['-S'], stderr=subprocess.STDOUT)
        output = output.decode('ascii')

        logging.info("Current status")
        for line in output.split('\n'):
            logging.info(line)

        if 'started as' not in output:
            logging.error('noip2 daemon has stopped running. Restarting it in 60 seconds.')
            time.sleep(60)
            break

        time.sleep(60)
