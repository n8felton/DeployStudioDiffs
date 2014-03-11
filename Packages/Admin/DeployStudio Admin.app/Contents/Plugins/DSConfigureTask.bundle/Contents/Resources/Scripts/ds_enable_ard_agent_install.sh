#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
SCRIPT_PATH=`dirname "${0}"`

echo "${SCRIPT_NAME} - v1.6 ("`date`")"

if [ ${#} -lt 1 ]
then
  echo "Command: ${SCRIPT_NAME} ${*}"
  echo "Usage: ${SCRIPT_NAME} <volume name> [admin-group]"
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
  echo "Usage: ${SCRIPT_NAME} <volume name> [admin-group]"
  echo "RuntimeAbortWorkflow: \"${VOLUME_PATH}\" volume not found!"
  exit 1
fi

sed s/__ADMIN_GROUP__/"${2}"/g "${SCRIPT_PATH}"/ds_enable_ard_agent/ds_enable_ard_agent.sh > "${VOLUME_PATH}"/etc/deploystudio/bin/ds_enable_ard_agent.sh
	
chmod 700 "${VOLUME_PATH}"/etc/deploystudio/bin/ds_enable_ard_agent.sh
chown root:wheel "${VOLUME_PATH}"/etc/deploystudio/bin/ds_enable_ard_agent.sh

echo "${SCRIPT_NAME} - end"

exit 0
