#!/bin/sh

VERSION=1.1

SYS_VERS=`sw_vers -productVersion | awk -F. '{ print $2 }'`

SETREGPROPTOOL=`dirname "${0}"`/setregproptool 

if [ -e "${SETREGPROPTOOL}" ] && [ ${SYS_VERS} -ge 6 ]
then
  "${SETREGPROPTOOL}" -c
  if [ ${?} -eq 0 ]
  then
    echo "status: on"
    exit 0
  fi
fi

echo "status: off"

exit 0
