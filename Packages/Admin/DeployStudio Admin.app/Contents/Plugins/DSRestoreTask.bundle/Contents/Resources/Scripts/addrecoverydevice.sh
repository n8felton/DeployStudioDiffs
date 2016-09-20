#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
VERSION=1.1
SYS_VERS=`sw_vers -productVersion | awk -F. '{ print $2 }'`

if [ ${SYS_VERS} -lt 7 ]
then
  echo "This script requires macOS 10.7 or later!" >>/dev/stderr
  exit 1
fi

if [ -z "${1}" ]
then
  echo "Usage: ${SCRIPT_NAME} <target volume> [<partition size in bytes>]" >>/dev/stderr
  echo "Example: ${SCRIPT_NAME} 'Macintosh HD' 650002432" >>/dev/stderr
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
  RECOVERY_SIZE_B=${2}
else
  RECOVERY_SIZE_B=650002432
fi

RECOVERY_DEVICE_ID=
LV_UUID=`diskutil cs info "${VOL}" 2>/dev/null | grep "^ *UUID:" | sed -e "s/^.* //"`
if [ -n "${LV_UUID}" ]
then
  LV_SIZE_B=`diskutil cs info "$LV_UUID" | grep "LV Size:"  | sed -e "s/[^0-9]*//g"`
  NEW_LV_SIZE_B=`expr ${LV_SIZE_B} - ${RECOVERY_SIZE_B}`
  diskutil cs resizeStack "$LV_UUID" ${NEW_LV_SIZE_B}B JHFS+ "Recovery HD" ${RECOVERY_SIZE_B}B >>/dev/stderr
  if [ ${?} -ne 0 ]
  then
    echo "RuntimeAbortScript"
    exit 1
  fi
  sleep 5
  RECOVERY_DEVICE_ID=`diskutil info "Recovery HD" | grep "Device Identifier:" | sed s/.*disk/disk/`
fi

echo "RECOVERY_DEVICE=${RECOVERY_DEVICE_ID}"

exit 0
