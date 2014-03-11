#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
VERSION=1.0

remove_existing_context() {
  if [ -e "${1}.bootstrap" ]
  then
    echo "Removing existing file \"${1}.bootstrap\"..."
    rm -f "${1}.bootstrap"
  fi
  if [ -e "${1}.bcd" ]
  then
    echo "Removing existing file \"${1}.bcd\"..."
    rm -f "${1}.bcd"
  fi
  if [ -e "${1}.ini" ]
  then
    echo "Removing existing file \"${1}.ini\"..."
    rm -f "${1}.ini"
  fi
  if [ -e "${1}.id" ]
  then
    echo "Removing existing file \"${1}.id\"..."
    rm -f "${1}.id"
  fi
}

if [ ${#} -lt 2 ]
then
  echo "Usage: ${SCRIPT_NAME} disk<ID>s<partition index> <image file path>"
  echo "Example: ${SCRIPT_NAME} disk0s3 /Volumes/Sharepoint/myimage"
  exit 1
fi

echo "Running ${SCRIPT_NAME} v${VERSION}"

DISK_ID=`basename "${1}" | sed s/disk// | awk -Fs '{ print $1 }'`
PARTITION_ID=`basename "${1}" | sed s/disk// | awk -Fs '{ print $2 }'`

DEVICE=/dev/disk${DISK_ID}
if [ ! -e "${DEVICE}" ]
then
  echo "Unknown device ${DEVICE}, script aborted."
  exit 1
fi

if [ -n "${PARTITION_ID}" ]
then
  NTFS_DEVICE=${DEVICE}s${PARTITION_ID}
else
  NTFS_DEVICE=${DEVICE}
fi

if [ ! -e "${NTFS_DEVICE}" ]
then
  echo "Unknown device ${NTFS_DEVICE}, script aborted."
  echo "RuntimeAbortScript"
  exit 1
fi

# checking target image path
TARGET_FILE_PATH="${2}"
IMAGE_NAME=`basename "${TARGET_FILE_PATH}"`
TARGET_FOLDER=`dirname "${TARGET_FILE_PATH}"`
if [ ! -e "${TARGET_FOLDER}" ]
then
  echo "Destination path ${TARGET_FOLDER} not found, script aborted."
  echo "RuntimeAbortScript"
  exit 1
fi
remove_existing_context "${TARGET_FILE_PATH}"

IMAGE_FILE_PATH="${TARGET_FILE_PATH}"

# saving windows boot config files
NTFS_MOUNT_POINT=/Volumes/`diskutil info ${NTFS_DEVICE} | grep "Mount Point:" | awk -F"/Volumes/" '{ print $2 }'`
if [ -e "${NTFS_MOUNT_POINT}/boot.ini" ]
then
  echo "Saving boot.ini file from mount point ${NTFS_MOUNT_POINT} to ${IMAGE_FILE_PATH}.ini..."
  cp -X "${NTFS_MOUNT_POINT}/boot.ini" "${IMAGE_FILE_PATH}.ini"
fi
if [ -e "${NTFS_MOUNT_POINT}/Boot/BCD" ]
then
  echo "Saving Boot/BCD file from mount point ${NTFS_MOUNT_POINT} to ${IMAGE_FILE_PATH}.bcd..."
  cp -X "${NTFS_MOUNT_POINT}/Boot/BCD" "${IMAGE_FILE_PATH}.bcd"
fi

# saving the MBR bootstrap code
echo "Saving MBR bootstrap code from device ${DEVICE} to ${IMAGE_FILE_PATH}.bootstrap..."
dd if="${DEVICE}" of="${IMAGE_FILE_PATH}.bootstrap" bs=446 count=1

# saving the partition filesystem identifier
echo "Saving filesystem identifier for partition ${NTFS_DEVICE} to ${IMAGE_FILE_PATH}.id..."
FS_ID=`fdisk ${DEVICE} | grep "^.${PARTITION_ID}:" | awk '{ print $2 }'`
let FS_ID_INT=0x${FS_ID}
if [ ${FS_ID_INT} -gt 0 ] && [ ${FS_ID_INT} -le 255 ]
then
  echo ${FS_ID} > "${IMAGE_FILE_PATH}.id"
fi

exit 0
