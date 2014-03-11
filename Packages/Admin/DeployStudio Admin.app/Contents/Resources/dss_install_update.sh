#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
SCRIPT_PATH=`dirname "${0}"`

echo "${SCRIPT_NAME} - v1.0 ("`date`")"

INSTALLER_PACKAGE_PATH="/tmp/DeployStudioServer.mpkg"

if [ ! -e "${INSTALLER_PACKAGE_PATH}" ]
then
  echo "\"${INSTALLER_PACKAGE_PATH}\" file not found!"
  exit 1
fi

export COMMAND_LINE_INSTALL=1
installer -pkg "${INSTALLER_PACKAGE_PATH}" -target / -verboseR
if [ ${?} -eq 0 ]
then
  echo "Installation successful, deleting temporary files..."
  rm -rf "${INSTALLER_PACKAGE_PATH}"
else
  echo "An error occurred while installing the package \"${INSTALLER_PACKAGE_PATH}\"!"
  echo "${SCRIPT_NAME} - end"
  exit 1
fi

echo "${SCRIPT_NAME} - end"
exit 0
