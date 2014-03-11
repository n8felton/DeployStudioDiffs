#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
VERSION=1.2

if [ ${#} -lt 1 ]
then
  echo "Usage: ${SCRIPT_NAME} <disk image path> [--reconvertbeforescanning]"
  echo "Example: ${SCRIPT_NAME} /tmp/diskimage.dmg --reconvertbeforescanning"
  exit 1
fi

echo "Running ${SCRIPT_NAME} v${VERSION}"

ASR_VERS=`/usr/sbin/asr -v 2>&1 | awk '{ print $3 }'`

RECONVERT_BEFORE_SCANNING="NO"
if [ ${#} -gt 1 ]
then
  if [ "${2}" = "--reconvertbeforescanning" ]
  then
    RECONVERT_BEFORE_SCANNING="YES"
  fi
fi
if [ "${RECONVERT_BEFORE_SCANNING}" = "YES" ]
then
  FORMAT=`/usr/bin/hdiutil imageinfo -format "${1}"`
  if [ -n "${FORMAT}" ]
  then
    TEMP_FILE=`/usr/bin/dirname "${1}"`/.tmp.`/usr/bin/basename "${1}"`
    echo "Convert first the image to the same format as it seems to improve multicast reliability (${TEMP_FILE})."
    /usr/bin/hdiutil convert -format "${FORMAT}" "${1}" -o "${TEMP_FILE}"
    if [ ${?} -eq 0 ]
    then
      rm "${1}"
      mv -f "${TEMP_FILE}" "${1}"
    fi
  fi
fi

if [ -n "${ASR_VERS}" ] && [ ${ASR_VERS} -ge 142 ]
then
  SCAN_OPTIONS="--allowfragmentedcatalog"
fi

echo "Image scan..."
/usr/sbin/asr imagescan --source "${1}" ${SCAN_OPTIONS} --verbose
if [ ${?} -ne 0 ]
then
  echo "Failed scan the disk image '${1}', script aborted."
  echo "RuntimeAbortScript"
  exit 1
fi

echo "Exiting ${SCRIPT_NAME} v${VERSION}"

exit 0
