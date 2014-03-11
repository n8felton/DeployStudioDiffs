#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
VERSION=1.0
SYS_VERS=`sw_vers -productVersion | awk -F. '{ print $2 }'`

if [ -z "${1}" ]
then
  echo "Usage: ${SCRIPT_NAME} <volume name>" >>/dev/stderr
  echo "Example: ${SCRIPT_NAME} 'Macintosh HD'" >>/dev/stderr
  exit 1
fi

if [ ! -e "${1}" ] && [ ! -e "/Volumes/${1}" ] && [ ! -e "/dev/${1}" ]
then
  echo "Error: volume '${1}' not found!" >>/dev/stderr
  exit 1re
fi

if [ -e "${1}" ]
then
  VOL="${1}"
elif [ -e "/Volumes/${1}" ]
then
  VOL="/Volumes/${1}"
else
  VOL="/dev/${1}"
fi

if [ ${SYS_VERS} -ge 7 ]
then
  VOL_UUID=`diskutil cs info "${VOL}" 2>/dev/null | grep "^ *UUID:" | sed -e "s/^.* //"`
  if [ -n "${VOL_UUID}" ]
  then
    RECOVERY_DEVICE_ID=
    PV_UUIDS=`diskutil cs list | grep "Physical Volume" | sed -e "s/^.* //"`
    for PV_UUID in ${PV_UUIDS}
    do
      DEVICE_ID=`diskutil cs info ${PV_UUID} | grep "Device Identifier:" | sed -e "s/.*disk/disk/"`
      RECOVERY_DEVICE_ID=`diskutil list "${DEVICE_ID%s*}" | grep -m 1 -E 'Apple_Boot +Recovery HD' | sed -e "s/.*disk/disk/"`
      if [ -n "${RECOVERY_DEVICE_ID}" ]
      then
        break
      fi
    done
  else
    DEVICE_ID=`diskutil info "${VOL}" | grep "^ *Device Identifier:" | sed -e "s/^.* //"`
    RECOVERY_DEVICE_ID=`diskutil list ${DEVICE_ID} | grep -m 1 -E 'Apple_Boot +Recovery HD' | sed -e "s/.*disk/disk/"`
  fi
else
  DEVICE_ID=`diskutil info "${VOL}" | grep "^ *Device Identifier:" | sed -e "s/^.* //"`
  RECOVERY_DEVICE_ID=`diskutil list ${DEVICE_ID} | grep -m 1 -E 'Apple_Boot +Recovery HD' | sed -e "s/.*disk/disk/"`
fi

if [ -n "${RECOVERY_DEVICE_ID}" ]
then
  echo "RECOVERY_DEVICE=${RECOVERY_DEVICE_ID}"
fi

exit 0
