#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
VERSION=1.2

if [ ${#} -lt 2 ]
then
  echo "Usage: ${SCRIPT_NAME} <bootstrap file> disk<ID>"
  echo "Example: ${SCRIPT_NAME} image.bootstrap[.gz] disk0"
  exit 1
fi

echo "Running ${SCRIPT_NAME} v${VERSION}"

BOOTSTRAP_FILE=`echo "${1}" | sed s/".ntfs"/".bootstrap"/ | sed s/".dev.dmg"/".bootstrap"/ | sed s/".fat.dmg"/".bootstrap"/`
if [ ! -e "${BOOTSTRAP_FILE}" ]
then
  echo "File \"${BOOTSTRAP_FILE}\" not found, script aborted."
  exit 1
fi

DISK_ID=`basename "${2}" | sed s/disk// | awk -Fs '{ print $1 }'`

DEVICE=/dev/disk${DISK_ID}
if [ ! -e "${DEVICE}" ]
then
  echo "Unknown device ${DEVICE}, script aborted."
  exit 1
fi
RAW_DEVICE=/dev/rdisk${DISK_ID}

# unmount device
echo "-> unmounting device ${DEVICE}..."
OUTPUT=`diskutil unmountDisk force "${DEVICE}" 2>&1`
if [ ${?} -ne 0 ] || [[ ! "${OUTPUT}" =~ "successful" ]]
then
  echo "Failed to unmount device ${DEVICE}, script aborted."
  echo "RuntimeAbortScript"
  exit 1
fi

# restore the MBR bootstrap code
if [ -e "${BOOTSTRAP_FILE}.gz" ]
then
  echo "-> uncompressing MBR bootstrap code (${BOOTSTRAP_FILE}.gz)..."
  gunzip "${BOOTSTRAP_FILE}.gz"
fi
if [ -e "${BOOTSTRAP_FILE}" ]
then
  echo "-> restoring MBR bootstrap code (${BOOTSTRAP_FILE})..."
  #dd if="${BOOTSTRAP_FILE}" of="${DEVICE}" bs=446 count=1
  fdisk -y -u -f "${BOOTSTRAP_FILE}" "${RAW_DEVICE}"
fi 

# remount device
echo "-> mounting device ${DEVICE}..."
diskutil mountDisk "${DEVICE}"

exit 0
