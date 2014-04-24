#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
SCRIPT_PATH=`dirname "${0}"`

echo "${SCRIPT_NAME} - v1.0 ("`date`")"

if [ ${#} -ne 1 ]
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

printf '#!/bin/sh\n\n/usr/sbin/spctl --master-disable\n\nexit 0\n' > "${VOLUME_PATH}"/etc/deploystudio/bin/ds_disable_gatekeeper.sh
chmod 700 "${VOLUME_PATH}"/etc/deploystudio/bin/ds_disable_gatekeeper.sh
chown root:wheel "${VOLUME_PATH}"/etc/deploystudio/bin/ds_disable_gatekeeper.sh

echo "${SCRIPT_NAME} - end"

exit 0
