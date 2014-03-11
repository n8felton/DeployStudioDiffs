#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
SCRIPT_PATH=`dirname "${0}"`

echo "${SCRIPT_NAME} - v1.0 ("`date`")"

if [ ${#} -ne 1 ]
then
  echo "RuntimeAbortWorkflow: missing arguments!"
  echo "Usage: ${SCRIPT_NAME} <volume name>"
  exit 1
fi

if [ "${1}" = "/" ]
then
  VOLUME_PATH=/
else
  VOLUME_PATH=/Volumes/${1}
fi

if [ ! -e "${VOLUME_PATH}" ]
then
  echo "RuntimeAbortWorkflow: \"${VOLUME_PATH}\" volume not found!"
  echo "Usage: ${SCRIPT_NAME} <volume name>"
  exit 1
fi

defaults write "${VOLUME_PATH}"/Library/Preferences/com.apple.SoftwareUpdate ScheduleFrequency -int -1
chmod 644 "${VOLUME_PATH}"/Library/Preferences/com.apple.SoftwareUpdate.plist
chown root:admin "${VOLUME_PATH}"/Library/Preferences/com.apple.SoftwareUpdate.plist
rm "${VOLUME_PATH}"/Library/Preferences/com.apple.SoftwareUpdate.plist.lockfile &>/dev/null

echo "${SCRIPT_NAME} - end"

exit 0
