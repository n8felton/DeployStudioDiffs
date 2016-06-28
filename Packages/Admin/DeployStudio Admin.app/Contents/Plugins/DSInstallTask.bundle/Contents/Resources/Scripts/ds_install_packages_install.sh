#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
SCRIPT_PATH=`dirname "${0}"`

echo "${SCRIPT_NAME} - v1.15 ("`date`")"

if [ ${#} -lt 2 ]
then
  echo "Command: ${SCRIPT_NAME} ${*}"
  echo "Usage: ${SCRIPT_NAME} <volume name> <package index file> [--ignore-install-status]"
  echo "RuntimeAbortWorkflow: invalid number of arguments!"
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
  echo "Usage: ${SCRIPT_NAME} <volume name> <package index file> [--ignore-install-status]"
  echo "RuntimeAbortWorkflow: \"${VOLUME_PATH}\" volume not found!"
  exit 1
fi

if [ ! -e "${VOLUME_PATH}/etc/deploystudio/ds_packages/${2}" ]
then
  echo "Command: ${SCRIPT_NAME} ${*}"
  echo "Usage: ${SCRIPT_NAME} <volume name> <package index file> [--ignore-install-status]"
  echo "RuntimeAbortWorkflow: \"${VOLUME_PATH}/etc/deploystudio/ds_packages/${2}\" package index file not found!"
  exit 1
fi

if [ ! -e "${VOLUME_PATH}/etc/deploystudio/ds_packages" ]
then
  mkdir -p "${VOLUME_PATH}"/etc/deploystudio/ds_packages
fi
chmod 755 "${VOLUME_PATH}"/etc/deploystudio/ds_packages
chown root:wheel "${VOLUME_PATH}"/etc/deploystudio/ds_packages

IDX=`basename "${2}" | awk -F. '{ print $1 }'`
if [ -n "${3}" ]
then
  IGNORE_INSTALL_STATUS="YES"
else
  IGNORE_INSTALL_STATUS="NO"
fi
sed -e s/__PACKAGE_INDEX__/"${IDX}"/g \
	-e s/__IGNORE_INSTALL_STATUS__/"${IGNORE_INSTALL_STATUS}"/g \
       "${SCRIPT_PATH}"/ds_install_packages/ds_install_packages.sh > "${VOLUME_PATH}"/etc/deploystudio/bin/ds_install_packages_${IDX}.sh

chmod 700 "${VOLUME_PATH}"/etc/deploystudio/bin/ds_install_packages_${IDX}.sh
chown root:wheel "${VOLUME_PATH}"/etc/deploystudio/bin/ds_install_packages_${IDX}.sh

#"${SCRIPT_PATH}"/ds_enable_verbose_reboot.sh "${1}"

echo "${SCRIPT_NAME} - end"

exit 0
