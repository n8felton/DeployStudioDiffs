#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
SCRIPT_PATH=`dirname "${0}"`

echo "${SCRIPT_NAME} - v1.20 ("`date`")"

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

if [ ! -e "${VOLUME_PATH}"/etc/deploystudio/bin/ds_active_directory_binding.plist ]
then
  echo "Command: ${SCRIPT_NAME} ${*}"
  echo "Usage: ${SCRIPT_NAME} <volume name>"
  echo "RuntimeAbortWorkflow: \"${VOLUME_PATH}/etc/deploystudio/bin/ds_active_directory_binding.plist\" configuration file not found!"
  exit 1
else
  chmod 600 "${VOLUME_PATH}"/etc/deploystudio/bin/ds_active_directory_binding.plist
  chown root:wheel "${VOLUME_PATH}"/etc/deploystudio/bin/ds_active_directory_binding.plist
fi

VOLUME_SYS=`defaults read "${VOLUME_PATH}"/System/Library/CoreServices/SystemVersion ProductVersion | awk -F. '{ print $2 }'`
if [ -z "${VOLUME_SYS}" ]
then
  VOLUME_SYS=`sw_vers -productVersion | awk -F. '{ print $2 }'`
fi

if [ ${VOLUME_SYS} -lt 7 ]
then
  cp "${SCRIPT_PATH}"/ds_active_directory_binding/ds_active_directory_binding.10.5.sh "${VOLUME_PATH}"/etc/deploystudio/bin/ds_active_directory_binding.sh
else
  cp "${SCRIPT_PATH}"/ds_active_directory_binding/ds_active_directory_binding.10.7.sh "${VOLUME_PATH}"/etc/deploystudio/bin/ds_active_directory_binding.sh
fi
if [ ${?} -ne 0 ]
then
  echo "RuntimeAbortWorkflow: AD binding script installation failed!"
  exit 1
fi
	
chmod 700 "${VOLUME_PATH}"/etc/deploystudio/bin/ds_active_directory_binding.sh
chown root:wheel "${VOLUME_PATH}"/etc/deploystudio/bin/ds_active_directory_binding.sh

if [ -e "${VOLUME_PATH}"/System/Library/CoreServices/ServerVersion.plist ]
then
  rm -rf "${VOLUME_PATH}/Library/Preferences/OpenDirectory/Configurations/Active Directory" &>/dev/null
  rm -rf "${VOLUME_PATH}/Library/Preferences/OpenDirectory/DynamicData/Active Directory" &>/dev/null
  rm -f  "${VOLUME_PATH}"/Library/Preferences/DirectoryService/ActiveDirectory.plist &>/dev/null
  rm -f  "${VOLUME_PATH}"/var/db/dslocal/nodes/Default/config/KerberosKDC.plist &>/dev/null
  rm -f  "${VOLUME_PATH}"/Library/Keychains/System.keychain &>/dev/null
  rm -f  "${VOLUME_PATH}"/etc/krb5.keytab &>/dev/null
  rm -rf "${VOLUME_PATH}"/var/db/krb5kdc &>/dev/null
fi

#"${SCRIPT_PATH}"/ds_enable_verbose_reboot.sh "${1}"

echo "${SCRIPT_NAME} - end"

exit 0