#!/usr/bin/env sh
cat >/etc/motd <<EOL
    _   ___ ___  _  _ ___ _____    ___
   /_\ / __| _ \| \| | __|_   _|  / __|___ _ _ ___
  / _ \\\__ \  _/| .\` | _|  | |   | (__/ _ \ '_/ -_)
 /_/ \_\___/_|(_)_|\_|___| |_|    \___\___/_| \___|

$(source /etc/os-release;echo $PRETTY_NAME)
ASP.NET Core v${ASPNET_VERSION}
Startup $(date +'%Y-%m-%d %T %z') ${TZ}
EOL
cat /etc/motd

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
  if [ ! -z "${SSH_PORT}" ]; then
    sed -i "s/SSH_PORT/$SSH_PORT/g" /etc/ssh/sshd_config
  fi
  /usr/sbin/sshd

  $_STARTUP_COMMAND
else
  echo "Missing startup command. Please use command line arguments or environment variable \$STARTUPCOMMAND."
fi
