#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
SCRIPT_PATH=`dirname "${0}"`

echo "${SCRIPT_NAME} - v1.8 ("`date`")"

if [ ${#} -lt 1 ]
then
  echo "Command: ${SCRIPT_NAME} ${*}"
  echo "Usage: ${SCRIPT_NAME} <volume name> [<server hostname> [-resetWhenDone]]"
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
  echo "Usage: ${SCRIPT_NAME} <volume name> [<server hostname> [-resetWhenDone]]"
  echo "RuntimeAbortWorkflow: \"${VOLUME_PATH}\" volume not found!"
  exit 1
fi

sed -e s/__SUS_HOST_NAME__/"${2}"/g -e s/__RESET_WHEN_DONE__/"${3}"/g "${SCRIPT_PATH}"/ds_software_update/ds_software_update.pl > "${VOLUME_PATH}"/etc/deploystudio/bin/ds_software_update.pl
chmod 700 "${VOLUME_PATH}"/etc/deploystudio/bin/ds_software_update.pl
chown root:wheel "${VOLUME_PATH}"/etc/deploystudio/bin/ds_software_update.pl

rm "${VOLUME_PATH}"/etc/deploystudio/bin/.ds_software_update.calls 2>/dev/null

#"${SCRIPT_PATH}"/ds_enable_verbose_reboot.sh "${1}"

echo "${SCRIPT_NAME} - end"

exit 0
