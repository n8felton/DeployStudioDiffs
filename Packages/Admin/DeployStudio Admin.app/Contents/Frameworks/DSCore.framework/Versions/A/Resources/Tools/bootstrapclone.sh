#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
VERSION=1.2

if [ ${#} -lt 2 ]
then
  echo "Usage: ${SCRIPT_NAME} disk<ID> <image file path>"
  echo "Example: ${SCRIPT_NAME} disk0 /backup/image"
  exit 1
fi

echo "Running ${SCRIPT_NAME} v${VERSION}"

DISK_ID=`basename "${1}" | sed s/disk// | awk -Fs '{ print $1 }'`

DEVICE=/dev/disk${DISK_ID}
if [ ! -e "${DEVICE}" ]
then
  echo "Unknown device ${DEVICE}, script aborted."
  exit 1
fi

IMAGE_FILE_PATH="${2}"
if [ -e "${IMAGE_FILE_PATH}.bootstrap" ]
then
  echo "-> removing existing file \"${IMAGE_FILE_PATH}.bootstrap\"..."
  rm -f "${IMAGE_FILE_PATH}.bootstrap"
fi


# saving the MBR bootstrap code
echo "-> saving MBR bootstrap code from device ${DEVICE} to ${IMAGE_FILE_PATH}.bootstrap..."
dd if="${DEVICE}" of="${IMAGE_FILE_PATH}.bootstrap" bs=446 count=1

exit 0
