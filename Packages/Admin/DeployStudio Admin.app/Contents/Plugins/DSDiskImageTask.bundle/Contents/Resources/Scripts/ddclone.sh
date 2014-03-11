#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
VERSION=1.7

remove_existing_image() {
  if [ -e "${1}.dd" ]
  then
    echo "Removing existing file \"${1}.dd\"..."
    rm -f "${1}.dd"
  fi
  if [ -e "${1}.dd.gz" ]
  then
    echo "Removing existing file \"${1}.dd.gz\"..."
    rm -f "${1}.dd.gz"
  fi
  if [ -e "${1}.bootstrap" ]
  then
    echo "Removing existing file \"${1}.bootstrap\"..."
    rm -f "${1}.bootstrap"
  fi
  if [ -e "${1}.id" ]
  then
    echo "Removing existing file \"${1}.id\"..."
    rm -f "${1}.id"
  fi
}

if [ ${#} -lt 2 ]
then
  echo "Usage: ${SCRIPT_NAME} disk<ID>s<partition index> <image file path> [<scratch disk> [--compress]]"
  echo "Example: ${SCRIPT_NAME} disk0s3 /Volumes/Sharepoint/myimage /Volumes/Scratch --compress"
  echo "RuntimeAbortScript"
  exit 1
fi

echo "Running ${SCRIPT_NAME} v${VERSION}"

DISK_ID=`basename "${1}" | sed s/disk// | awk -Fs '{ print $1 }'`
PARTITION_ID=`basename "${1}" | sed s/disk// | awk -Fs '{ print $2 }'`

DEVICE=/dev/disk${DISK_ID}
if [ ! -e "${DEVICE}" ]
then
  echo "Unknown device ${DEVICE}, script aborted."
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
remove_existing_image "${TARGET_FILE_PATH}"

# checking optional scratch disk 
SCRATCH_DISK="${3}"
if [ -n "${SCRATCH_DISK}" ]
then
  
  if [ ! -e "${SCRATCH_DISK}" ]
  then
    echo "Scratch disk ${SCRATCH_DISK} not found, script aborted."
    echo "RuntimeAbortScript"
    exit 1
  fi
  IMAGE_FILE_PATH="${SCRATCH_DISK}/${IMAGE_NAME}"
  remove_existing_image "${IMAGE_FILE_PATH}"
else
  IMAGE_FILE_PATH="${TARGET_FILE_PATH}"
fi

# unmount device
echo "Unmounting device ${DEVICE}s${PARTITION_ID}..."
diskutil unmount force "${DEVICE}s${PARTITION_ID}" 2>/dev/null

# saving the MBR bootstrap code
echo "Saving MBR bootstrap code from device ${DEVICE} to ${IMAGE_FILE_PATH}.bootstrap..."
dd if="${DEVICE}" of="${IMAGE_FILE_PATH}.bootstrap" bs=446 count=1

# saving the partition filesystem identifier
echo "Saving filesystem identifier for partition ${DEVICE}s${PARTITION_ID} to ${IMAGE_FILE_PATH}.id..."
FS_ID=`fdisk ${DEVICE} | grep "^.${PARTITION_ID}:" | awk '{ print $2 }'`
let FS_ID_INT=0x${FS_ID}
if [ ${FS_ID_INT} -gt 0 ] && [ ${FS_ID_INT} -le 255 ]
then
  echo ${FS_ID} > "${IMAGE_FILE_PATH}.id"
fi

# cloning device partition
echo "Cloning the device partition ${DEVICE}s${PARTITION_ID} to ${IMAGE_FILE_PATH}.dd..."
/bin/dd if=${DEVICE}s${PARTITION_ID} of="${IMAGE_FILE_PATH}.dd" bs=16384k &>/tmp/${$}.log &
DD_PID=${!}
DD_RUNNING=1
while [ ${DD_RUNNING} -eq 1 ]
do
  /bin/kill -SIGINFO ${DD_PID} &>/dev/null
  if [ ${?} -ne 0 ]
  then
    DD_RUNNING=0
  else
    echo "dd-progress="`tail -n1 /tmp/${$}.log | awk '{ print $1 }'`
	sleep 5
  fi
done
echo "dd-progress="`tail -n1 /tmp/${$}.log | awk '{ print $1 }'`
#if [ ${?} -ne 0 ]
#then
#  echo "An error occurred while cloning the device, script aborted."
#  echo "Remounting device ${DEVICE}s${PARTITION_ID}..."
#  diskutil mount "${DEVICE}s${PARTITION_ID}" 2>/dev/null
#  echo "RuntimeAbortScript"
#  exit 1
#fi

# remount device
echo "Remounting device ${DEVICE}s${PARTITION_ID}..."
diskutil mount "${DEVICE}s${PARTITION_ID}" 2>/dev/null

# compress device disk image
if [ -n "${4}" ] && [ "${4}" == "--compress" ]
then
  echo "Compressing disk image..."
  gzip "${IMAGE_FILE_PATH}.dd"
fi

# moving files from the scratch disk to the target path
if [ -n "${SCRATCH_DISK}" ]
then
  echo "Uploading disk image files to the repository..."
  cp "${IMAGE_FILE_PATH}.bootstrap" "${TARGET_FILE_PATH}.bootstrap"
  if [ ${?} -ne 0 ]
  then
    echo "An error occurred while moving the bootstrap file to ${TARGET_FOLDER}, script aborted."
    echo "RuntimeAbortScript"
    exit 1
  fi
  if [ -n "${4}" ] && [ "${4}" == "--compress" ]
  then
    cp "${IMAGE_FILE_PATH}.dd.gz" "${TARGET_FILE_PATH}.dd.gz"
  else
    cp "${IMAGE_FILE_PATH}.dd" "${TARGET_FILE_PATH}.dd"
  fi
  if [ ${?} -ne 0 ]
  then
    echo "An error occurred while moving the device image file to ${TARGET_FOLDER}, script aborted."
    echo "RuntimeAbortScript"
    exit 1
  fi
  remove_existing_image "${IMAGE_FILE_PATH}"
fi

exit 0
