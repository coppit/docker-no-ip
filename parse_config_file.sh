#!/bin/bash

# Container-specific stuff first

REQUIRED_SETTINGS="USERNAME PASSWORD DOMAINS"
DEFAULT_SETTINGS="INTERVAL=30m DEBUG=false"

TEMPLATE_CONFIG_FILE=/files/noip.conf
CONFIG_FILE=/config/noip.conf
GENERATED_CONFIG_FILE=/config/no-ip2.generated.conf
BREADCRUMB_FILE=/config/no-ip2.generated.conf.breadcrumb

EXPECT_SCRIPT=/files/create_config.exp

#-----------------------------------------------------------------------------------------------------------------------

validate_values() {
  if [ $(all_required_settings_exist) != true ]
  then
    echo "Missing required settings, which must be provided in the config file or by environment variables:"
    echo "$REQUIRED_SETTINGS"
    exit 0
  fi

  if [[ ! "$INTERVAL" =~ ^[0-9]+[mhd]$ ]]; then
    echo "INTERVAL must be a number followed by m, h, or d. Example: 5m"
    exit 2
  fi

  if [[ "${INTERVAL: -1}" == 'm' && "${INTERVAL:0:-1}" -lt 5 ]]; then
    echo "The shortest allowed INTERVAL is 5 minutes"
    exit 2
  fi

  if [ ${INTERVAL: -1} == 'm' ]
  then
    INTERVAL="${INTERVAL:: -1}"
  elif [ ${INTERVAL: -1} == 'h' ]
  then
    INTERVAL="$((${INTERVAL:: -1} * 60))"
  # Days
  else
    INTERVAL="$((${INTERVAL:: -1} * 60 * 24))"
  fi
}

#-----------------------------------------------------------------------------------------------------------------------

print_config() {
  echo "Configuration:"
  echo "  USERNAME=$USERNAME"
  echo "  PASSWORD=<hidden>"
  echo "  DOMAINS=$DOMAINS"
  echo "  INTERVAL=$INTERVAL"
  echo "  DEBUG=$DEBUG"
}

#-----------------------------------------------------------------------------------------------------------------------

generate_binary_config() {
  current_expect_script_md5=$(md5sum "$EXPECT_SCRIPT" | awk '{print $1}')
  current_md5=$(echo "$current_expect_script_md5|$USERNAME|$PASSWORD|$DOMAINS|$INTERVAL" | md5sum | awk '{print $1}')

  if [[ -f "$BREADCRUMB_FILE" ]]
  then
    breadcrumb_md5=$(cat "$BREADCRUMB_FILE")
  else
    breadcrumb_md5=""
  fi

  if [[ "$current_md5" == "$breadcrumb_md5" ]]
  then
    echo "Settings have not changed, so no need to regenerate the binary config file."
    return
  fi

  if ! expect "$EXPECT_SCRIPT" "$USERNAME" "$PASSWORD" "$DOMAINS" "$INTERVAL"
  then
    echo "Failed to create noip2 configuration file $GENERATED_CONFIG_FILE. Exiting"
    exit 4
  fi

  echo -n "$current_md5" > "$BREADCRUMB_FILE"
}

########################################################################################################################

ENV_VARS=/etc/envvars
MERGED_ENV_VARS=/etc/envvars.merged

#-----------------------------------------------------------------------------------------------------------------------

all_required_settings_exist() {
  ALL_REQUIRED_SETTINGS_EXIST=true
  for required_setting in $REQUIRED_SETTINGS
  do
    if [ -z "$(eval "echo \$$required_setting")" ]
    then
      ALL_REQUIRED_SETTINGS_EXIST=false
      break
    fi
  done

  echo $ALL_REQUIRED_SETTINGS_EXIST
}

#-----------------------------------------------------------------------------------------------------------------------

create_and_validate_config_file() {
  # Search for config file. If it doesn't exist, copy the default one
  if [ ! -f "$CONFIG_FILE" ]; then
    echo "Creating config file. Please do not forget to edit it to specify your settings!"
    cp "$TEMPLATE_CONFIG_FILE" "$CONFIG_FILE"
    chmod a+w "$CONFIG_FILE"
    exit 1
  fi

  # Check to see if they didn't edit the config file
  if diff "$TEMPLATE_CONFIG_FILE" "$CONFIG_FILE" >/dev/null
  then
    echo "Please edit the config file to specify your settings"
    exit 3
  fi

  # Translate line endings, since they may have edited the file in Windows
  PROCESSED_CONFIG_FILE=$(mktemp)

  tr -d '\r' < "$CONFIG_FILE" > "$PROCESSED_CONFIG_FILE"

  echo "$PROCESSED_CONFIG_FILE"
}

#-----------------------------------------------------------------------------------------------------------------------

merge_config_vars_and_env_vars() {
  SAFE_CONFIG_FILE=$1

  . "$SAFE_CONFIG_FILE"
  export $(grep = "$SAFE_CONFIG_FILE" | grep -v '^ *#' | cut -d= -f1)

  # Env vars take precedence
  . "$ENV_VARS"
  export $(cut -d= -f1 "$ENV_VARS")
}

#-----------------------------------------------------------------------------------------------------------------------

set_default_values() {
  # Handle defaults now
  for KEY_VALUE in $DEFAULT_SETTINGS
  do
    KEY=$(echo "$KEY_VALUE" | cut -d= -f1)
    VALUE=$(echo "$KEY_VALUE" | cut -d= -f2)

    eval "export $KEY=\${$KEY:=$VALUE}"
  done
}

########################################################################################################################

. "$ENV_VARS"

if [ $(all_required_settings_exist) = true ]
then
  echo "All required settings passed as environment variables. Skipping config file creation."
  exit 0
fi

SAFE_CONFIG_FILE=$(create_and_validate_config_file)

merge_config_vars_and_env_vars $SAFE_CONFIG_FILE

validate_values

set_default_values

print_config

generate_binary_config

# Now dump the envvars, in the style that boot.sh does. exec to avoid SHLVL=2
exec sh -c "export > \"$MERGED_ENV_VARS\""
