#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
SCRIPT_PATH=`dirname "${0}"`

echo "${SCRIPT_NAME} - v1.0 ("`date`")"

if [ ${#} -lt 1 ]
then
  echo "Command: ${SCRIPT_NAME} ${*}"
  echo "Usage: ${SCRIPT_NAME} <volume name>"
  echo "RuntimeAbortWorkflow: missing arguments!"
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
  echo "Command: ${SCRIPT_NAME} ${*}"
  echo "Usage: ${SCRIPT_NAME} <volume name>"
  echo "RuntimeAbortWorkflow: \"${VOLUME_PATH}\" volume not found!"
  exit 1
fi

cp "${SCRIPT_PATH}"/ds_freeze_homedirs/com.deploystudio.freezeHomedirs.plist "${VOLUME_PATH}"/Library/LaunchDaemons/com.deploystudio.freezeHomedirs.plist
chmod 644 "${VOLUME_PATH}"/Library/LaunchDaemons/com.deploystudio.freezeHomedirs.plist
chown root:wheel "${VOLUME_PATH}"/Library/LaunchDaemons/com.deploystudio.freezeHomedirs.plist
if [ ! -e "${VOLUME_PATH}"/usr/local/sbin ]
then
  mkdir -p "${VOLUME_PATH}"/usr/local/sbin
  chmod 755 "${VOLUME_PATH}"/usr/local "${VOLUME_PATH}"/usr/local/sbin
fi
cp "${SCRIPT_PATH}"/ds_freeze_homedirs/ds_freeze_homedirs.sh "${VOLUME_PATH}"/usr/local/sbin/ds_freeze_homedirs.sh
chmod 700 "${VOLUME_PATH}"/usr/local/sbin/ds_freeze_homedirs.sh
chown root:wheel "${VOLUME_PATH}"/usr/local/sbin/ds_freeze_homedirs.sh

echo "${SCRIPT_NAME} - end"

exit 0
