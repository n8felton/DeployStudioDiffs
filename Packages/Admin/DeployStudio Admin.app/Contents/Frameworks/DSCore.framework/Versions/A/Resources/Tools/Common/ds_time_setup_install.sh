#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
SCRIPT_PATH=`dirname "${0}"`

echo "${SCRIPT_NAME} - v1.7 ("`date`")"

if [ ${#} -lt 2 ]
then
  echo "Command: ${SCRIPT_NAME} ${*}"
  echo "Usage: ${SCRIPT_NAME} <volume name> <timezone> [<network time server 1> <network time server 2> ...]"
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
  echo "Usage: ${SCRIPT_NAME} <volume name> <timezone> [<network time server 1> <network time server 2> ...]"
  echo "RuntimeAbortWorkflow: \"${VOLUME_PATH}\" volume not found!"
  exit 1
fi

"${SCRIPT_PATH}"/ds_finalize_install.sh "${1}"

sed -e s:__TIMEZONE__:${2}:g \
    -e s:__NTP_SERVER__:${3}:g \
	"${SCRIPT_PATH}"/ds_time_setup/ds_time_setup.sh > "${VOLUME_PATH}"/etc/deploystudio/bin/ds_time_setup.sh	
	
chmod 700 "${VOLUME_PATH}"/etc/deploystudio/bin/ds_time_setup.sh
chown root:wheel "${VOLUME_PATH}"/etc/deploystudio/bin/ds_time_setup.sh

if [ -n "${3}" ]
then
  if [ -e "${VOLUME_PATH}"/etc/ntp.conf ]
  then
    rm "${VOLUME_PATH}"/etc/ntp.conf
  fi
  ntpdate "${3}"
fi

echo "${SCRIPT_NAME} - end"

exit 0
