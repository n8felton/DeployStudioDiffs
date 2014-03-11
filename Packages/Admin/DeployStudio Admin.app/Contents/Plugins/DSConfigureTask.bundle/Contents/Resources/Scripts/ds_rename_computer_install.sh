#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
SCRIPT_PATH=`dirname "${0}"`

echo "${SCRIPT_NAME} - v1.6 ("`date`")"

if [ ${#} -ne 3 ]
then
  echo "Command: ${SCRIPT_NAME} ${*}"
  echo "Usage: ${SCRIPT_NAME} <volume name> <local-host-name> <computer name>"
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
  echo "Usage: ${SCRIPT_NAME} <volume name> <local-host-name> <computer name>"
  echo "RuntimeAbortWorkflow: \"${VOLUME_PATH}\" volume not found!"
  exit 1
fi

sed -e s/__LOCAL_HOST_NAME__/"${2}"/g \
    -e s/__COMPUTER_NAME__/"${3}"/g \
    "${SCRIPT_PATH}"/ds_rename_computer/ds_rename_computer.sh > "${VOLUME_PATH}"/etc/deploystudio/bin/ds_rename_computer.sh
	
chmod 700 "${VOLUME_PATH}"/etc/deploystudio/bin/ds_rename_computer.sh
chown root:wheel "${VOLUME_PATH}"/etc/deploystudio/bin/ds_rename_computer.sh

echo "${SCRIPT_NAME} - end"

exit 0
