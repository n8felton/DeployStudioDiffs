#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
VERSION=1.0
SYS_VERS=`sw_vers -productVersion | awk -F. '{ print $2 }'`

if [ ${SYS_VERS} -lt 7 ]
then
  echo "This script requires macOS 10.7 or later!" >>/dev/stderr
  exit 1
fi

if [ ${#} -lt 3 ]
then
  echo "Usage: ${SCRIPT_NAME} disk<ID1> disk<ID2> <new volume name>" >>/dev/stderr
  echo "Example: ${SCRIPT_NAME} disk0 disk1 'Macintosh HD'" >>/dev/stderr
  exit 1
fi

TARGET_DEVICE0=`basename "${1}"`
TARGET_DEVICE1=`basename "${2}"`

LV_NAME=`diskutil cs list | grep "Volume Name:" | sed -e s/"Volume Name:"// -e s/"^ *"//`
if [ -n "${LV_NAME}" ]
then
  diskutil umount force "${LV_NAME}"
fi

PV_UUIDS=`diskutil cs list | grep "Physical Volume" | sed -e "s/^.* //"`
for PV_UUID in ${PV_UUIDS}
do
  DEVICE=`diskutil cs info ${PV_UUID} | grep "Device Identifier:" | sed -e "s/.*disk/disk/"`
  if [ "${DEVICE%s*}" = "${TARGET_DEVICE0}" ] || [ "${DEVICE%s*}" = "${TARGET_DEVICE1}" ]
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

LVG_NAME=`basename "${3}"`
LVG_UUID=`diskutil cs create "${LVG_NAME}" "${TARGET_DEVICE0}" "${TARGET_DEVICE1}" | grep "LVG UUID:" | sed -e "s/^.* //"`
if [ -z "${LVG_UUID}" ]
then
  echo "diskutil cs create failed!"
  echo "RuntimeAbortScript"
  exit 1
fi

sleep 5

LV_NAME=`basename "${3}"`
diskutil cs createVolume "${LVG_UUID}" JHFS+ "${LV_NAME}" 100%
if [ ${?} -ne 0 ]
then
  echo "RuntimeAbortScript"
  exit 1
fi

exit 0
