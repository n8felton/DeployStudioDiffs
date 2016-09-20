#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
VERSION=1.2
SYS_VERS=`sw_vers -productVersion | awk -F. '{ print $2 }'`

if [ ${SYS_VERS} -lt 7 ]
then
  echo "This script requires macOS 10.7 or later!" >>/dev/stderr
  exit 1
fi

if [ ${#} -lt 3 ]
then
  echo "Usage: ${SCRIPT_NAME} <target volume> <bootcamp volume name> <partition size in bytes>" >>/dev/stderr
  echo "Example: ${SCRIPT_NAME} 'Macintosh HD' 'BOOTCAMP' 1073741824" >>/dev/stderr
  exit 1
fi

if [ ! -e "${1}" ] && [ ! -e "/Volumes/${1}" ] && [ ! -e "/dev/${1}" ]
then
  echo "Error: volume '${1}' not found!" >>/dev/stderr
  exit 1
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

if [ -n "${2}" ]
then
  BOOTCAMP_NAME=${2}
else
  BOOTCAMP_NAME="BOOTCAMP"
fi

if [ -n "${3}" ]
then
  BOOTCAMP_SIZE_B=${3}
else
  BOOTCAMP_SIZE_B=1073741824
fi

BOOTCAMP_DEVICE_ID=
LV_UUID=`diskutil cs info "${VOL}" 2>/dev/null | grep "^ *UUID:" | sed -e "s/^.* //"`
if [ -n "${LV_UUID}" ]
then
  RECOVERY_SIZE_B=650002432
  LV_SIZE_B=`diskutil cs info "$LV_UUID" | grep "LV Size:"  | sed -e "s/[^0-9]*//g"`
  NEW_LV_SIZE_B=`expr ${LV_SIZE_B} - ${RECOVERY_SIZE_B} - ${BOOTCAMP_SIZE_B}`
  diskutil cs resizeStack "$LV_UUID" ${NEW_LV_SIZE_B}B "HFS+" "Recovery HD" ${RECOVERY_SIZE_B}B "MS-DOS FAT32" "${BOOTCAMP_NAME}" ${BOOTCAMP_SIZE_B}B >>/dev/stderr
  if [ ${?} -ne 0 ]
  then
    echo "RuntimeAbortScript"
    exit 1
  fi

  sleep 5

  RECOVERY_DEVICE_ID=`diskutil info "Recovery HD" | grep "Device Identifier:" | sed s/.*disk/disk/`
  diskutil umount force /dev/${RECOVERY_DEVICE_ID}
  asr adjust --target /dev/${RECOVERY_DEVICE_ID} --settype Apple_Boot
  if [ ${?} -ne 0 ]
  then
    echo "RuntimeAbortScript"
    exit 1
  fi

  BOOTCAMP_DEVICE_ID=`diskutil info "${BOOTCAMP_NAME}" | grep "Device Identifier:" | sed s/.*disk/disk/`
fi

echo "BOOTCAMP_DEVICE=${BOOTCAMP_DEVICE_ID}"

exit 0
