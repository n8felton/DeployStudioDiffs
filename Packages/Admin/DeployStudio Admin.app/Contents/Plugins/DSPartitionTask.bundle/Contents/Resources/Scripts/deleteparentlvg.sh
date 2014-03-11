#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
VERSION=1.0
SYS_VERS=`sw_vers -productVersion | awk -F. '{ print $2 }'`

if [ ${SYS_VERS} -lt 7 ]
then
  echo "This script requires OS X 10.7 or later!" >>/dev/stderr
  exit 1
fi

if [ -z "${1}" ]
then
  echo "Usage: ${SCRIPT_NAME} disk<ID>" >>/dev/stderr
  echo "Example: ${SCRIPT_NAME} disk0" >>/dev/stderr
  exit 1
fi

TARGET_DEVICE=`basename "${1}"`

PV_UUIDS=`diskutil cs list | grep "Physical Volume" | sed -e "s/^.* //"`
for PV_UUID in ${PV_UUIDS}
do
  DEVICE=`diskutil cs info ${PV_UUID} | grep "Device Identifier:" | sed -e "s/.*disk/disk/"`
  if [ "${DEVICE%s*}" = "${TARGET_DEVICE}" ]
  then
    PVG_UUID=`diskutil cs info ${PV_UUID} | grep "Parent LVG UUID" | sed -e "s/^.* //"`
    diskutil cs delete ${PVG_UUID}
    if [ ${?} -ne 0 ]
    then
      echo "RuntimeAbortScript"
      exit 1
    fi
  fi
done

exit 0
