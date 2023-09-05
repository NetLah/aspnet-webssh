#!/usr/bin/env sh
if [ "$(id -u)" -eq 0 ]; then
    _MOTD=/etc/motd
else
    _MOTD=/tmp/motd
fi

if [[ ! -f /tmp/motd ]] ; then
  cat >$_MOTD <<EOL
    _   ___ ___  _  _ ___ _____    ___
   /_\ / __| _ \| \| | __|_   _|  / __|___ _ _ ___
  / _ \\\__ \  _/| .\` | _|  | |   | (__/ _ \ '_/ -_)
 /_/ \_\___/_|(_)_|\_|___| |_|    \___\___/_| \___|

$(source /etc/os-release;echo $PRETTY_NAME)
ASP.NET Core v${ASPNET_VERSION}
Startup $(date +'%Y-%m-%d %T %z') ${TZ}
EOL
  touch /tmp/motd
fi

cat $_MOTD
echo "Launch: $(date +'%Y-%m-%d %T %z') ${TZ}"

_STARTUP_COMMAND=$*

if [ ! -z "${_STARTUP_COMMAND}" ]; then
  :
elif [ ! -z "${STARTUPCOMMAND}" ]; then
  _STARTUP_COMMAND=$STARTUPCOMMAND
elif [ ! -z "${STARTCOMMAND}" ]; then
  _STARTUP_COMMAND=$STARTCOMMAND
fi

if [ ! -z "${_STARTUP_COMMAND}" ]; then
  # starting sshd process
  if [ ! -z "${SSH_PORT}" ] && [ "$(id -u)" -eq 0 ]; then
    sed -i "s/SSH_PORT/$SSH_PORT/g" /etc/ssh/sshd_config
    /usr/sbin/sshd
  fi

  $_STARTUP_COMMAND
else
  echo "Missing startup command. Please use command line arguments or environment variable \$STARTUPCOMMAND."
fi
