#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
SCRIPT_PATH=`dirname "${0}"`

echo "${SCRIPT_NAME} - v1.0 ("`date`")"

if [ ${#} -lt 1 ]
then
  echo "Usage: ${SCRIPT_NAME} <dss installer archive path (dmg or zip)>"
  exit 1
fi

if [ -e "/tmp/DeployStudioServer.mpkg" ]
then
  rm -rf "/tmp/DeployStudioServer.mpkg"
fi

INSTALLER_ARCHIVE_PATH=${1}
if [ ! -e "${INSTALLER_ARCHIVE_PATH}" ]
then
  echo "\"${INSTALLER_ARCHIVE_PATH}\" file not found!"
  echo "Usage: ${SCRIPT_NAME} <dss installer archive path (dmg or zip)>"
  exit 1
fi

echo "${INSTALLER_ARCHIVE_PATH}" | grep -iqE ".dmg$"
if [ ${?} -eq 0 ]
then
  ARCHIVE_FORMAT="DMG"
else
  echo "${INSTALLER_ARCHIVE_PATH}" | grep -iqE ".zip$"
  if [ ${?} -eq 0 ]
  then
    ARCHIVE_FORMAT="ZIP"
  fi
fi

if [ -z "${ARCHIVE_FORMAT}" ]
then
  echo "Unsupported archive file format \"${INSTALLER_ARCHIVE_PATH}\"!"
  echo "Usage: ${SCRIPT_NAME} <dss installer archive path (dmg or zip)>"
  exit 1
fi

if [ "${ARCHIVE_FORMAT}" = "ZIP" ]
then
  PKG_FILE_NAME=`unzip -l "${INSTALLER_ARCHIVE_PATH}" | grep ".mpkg/$" | awk '{ print $4 }' | sed s+/$++`
  if [ -z "${PKG_FILE_NAME}" ]
  then
    echo "No installer package found in archive \"${INSTALLER_ARCHIVE_PATH}\"!"
    echo "Usage: ${SCRIPT_NAME} <dss installer archive path (dmg or zip)>"
    exit 1
  fi

  if [ -e "/tmp/${PKG_FILE_NAME}" ]
  then
    rm -rf "/tmp/${PKG_FILE_NAME}"
  fi

  unzip -o "${INSTALLER_ARCHIVE_PATH}" -d /tmp/
  if [ ${?} -eq 0 ]
  then
    mv "/tmp/${PKG_FILE_NAME}" "/tmp/DeployStudioServer.mpkg"
    echo "Installer extracted successfully, deleting temporary files..."
    rm -rf "${INSTALLER_ARCHIVE_PATH}"
  else
    echo "An error occurred while unarchiving \"${INSTALLER_ARCHIVE_PATH}\"!"
  fi
elif [ "${ARCHIVE_FORMAT}" = "DMG" ]
then
  hdiutil attach "${INSTALLER_ARCHIVE_PATH}"
  if [ ${?} -eq 0 ]
  then
    INSTALLER_VOLUME=`ls /Volumes/ | grep "^DeployStudioServer_" | head -n 1`
    if [ -n "${INSTALLER_VOLUME}" ]
    then
	  PACKAGE_NAME=`ls "/Volumes/${INSTALLER_VOLUME}" | grep "^DeployStudioServer_.*.mpkg$" | head -n 1`
	  if [ -n "${PACKAGE_NAME}" ]
	  then
	    PACKAGE_PATH="/Volumes/${INSTALLER_VOLUME}/${PACKAGE_NAME}"
		if [ -e "${PACKAGE_PATH}" ]
		then
		  echo "Installer extracted successfully!"
          ditto --rsrc "${PACKAGE_PATH}" "/tmp/DeployStudioServer.mpkg" 2>&1
		fi
      else
        echo "No installer package found in archive!"
	  fi
      hdiutil detach "/Volumes/${INSTALLER_VOLUME}"
      echo "Deleting temporary files..."
	  rm -f "${INSTALLER_ARCHIVE_PATH}"
    else
	  echo "DeployStudio Server installer volume not found!"
	fi
  else
    echo "An error occurred while mounting \"${INSTALLER_ARCHIVE_PATH}\"!"
  fi
fi

echo "${SCRIPT_NAME} - end"

exit 0
