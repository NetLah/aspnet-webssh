#!/usr/bin/env bash

echo "STARTUPCOMMAND: '$STARTUPCOMMAND' ${#STARTUPCOMMAND}"
echo "STARTCOMMAND: '$STARTCOMMAND' ${#STARTCOMMAND}"
_STARTUP_COMMAND=$*
echo "\$*: '$*' ${#_STARTUP_COMMAND}"

if [ ! -z "${_STARTUP_COMMAND}" ]; then
  echo "Use \$*: '$*'"
elif [ ! -z "${STARTUPCOMMAND}" ]; then
  echo "Use STARTUPCOMMAND: '$STARTUPCOMMAND'"
  _STARTUP_COMMAND=$STARTUPCOMMAND
elif [ ! -z "${STARTCOMMAND}" ]; then
  echo "Use STARTCOMMAND: '$STARTCOMMAND'"
  _STARTUP_COMMAND=$STARTCOMMAND
fi

if [ ! -z "${_STARTUP_COMMAND}" ]; then
  echo "Execute: '$_STARTUP_COMMAND'"
else
  echo "Missing startup command. Please use command line arguments or environment variable \$STARTUPCOMMAND."
fi
