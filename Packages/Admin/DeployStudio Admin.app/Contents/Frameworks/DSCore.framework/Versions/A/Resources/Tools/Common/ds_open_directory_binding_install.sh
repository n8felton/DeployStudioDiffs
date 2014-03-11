#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
SCRIPT_PATH=`dirname "${0}"`

echo "${SCRIPT_NAME} - v1.12 ("`date`")"

if [ ${#} -lt 2 ]
then
  echo "Command: ${SCRIPT_NAME} ${*}"
  echo "Usage: ${SCRIPT_NAME} <volume name> <binding id>"
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
  echo "Usage: ${SCRIPT_NAME} <volume name> <binding id>"
  echo "RuntimeAbortWorkflow: \"${VOLUME_PATH}\" volume not found!"
  exit 1
fi

if [ ! -e "${VOLUME_PATH}"/etc/deploystudio/bin/ds_open_directory_binding_${2}.plist ]
then
  echo "Command: ${SCRIPT_NAME} ${*}"
  echo "Usage: ${SCRIPT_NAME} <volume name> <binding id>"
  echo "RuntimeAbortWorkflow: \"${VOLUME_PATH}/etc/deploystudio/bin/ds_open_directory_binding_${2}.plist\" configuration file not found!"
  exit 1
else
  chmod 600 "${VOLUME_PATH}"/etc/deploystudio/bin/ds_open_directory_binding_${2}.plist
  chown root:wheel "${VOLUME_PATH}"/etc/deploystudio/bin/ds_open_directory_binding_${2}.plist
fi

VOLUME_SYS=`defaults read "${VOLUME_PATH}"/System/Library/CoreServices/SystemVersion ProductVersion | awk -F. '{ print $2 }'`
if [ -z "${VOLUME_SYS}" ]
then
  VOLUME_SYS=`sw_vers -productVersion | awk -F. '{ print $2 }'`
fi

if [ ${VOLUME_SYS} -lt 7 ]
then
  cp "${SCRIPT_PATH}"/ds_open_directory_binding/ds_open_directory_binding.10.5.sh "${VOLUME_PATH}"/etc/deploystudio/bin/ds_open_directory_binding_${2}.sh
else
  cp "${SCRIPT_PATH}"/ds_open_directory_binding/ds_open_directory_binding.10.7.sh "${VOLUME_PATH}"/etc/deploystudio/bin/ds_open_directory_binding_${2}.sh
fi

if [ ${?} -ne 0 ]
then
  echo "RuntimeAbortWorkflow: OD binding script installation failed!"
  exit 1
fi
	
chmod 700 "${VOLUME_PATH}"/etc/deploystudio/bin/ds_open_directory_binding_${2}.sh
chown root:wheel "${VOLUME_PATH}"/etc/deploystudio/bin/ds_open_directory_binding_${2}.sh

if [ -e "${VOLUME_PATH}"/System/Library/CoreServices/ServerVersion.plist ]
then
  rm -f  "${VOLUME_PATH}"/var/db/dslocal/nodes/Default/config/KerberosKDC.plist &>/dev/null
  rm -f  "${VOLUME_PATH}"/Library/Keychains/System.keychain &>/dev/null
  rm -f  "${VOLUME_PATH}"/etc/krb5.keytab &>/dev/null
  rm -rf "${VOLUME_PATH}"/var/db/krb5kdc &>/dev/null
fi

#"${SCRIPT_PATH}"/ds_enable_verbose_reboot.sh "${1}"

echo "${SCRIPT_NAME} - end"

exit 0