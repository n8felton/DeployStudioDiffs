#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
VERSION=2.2
SYS_VERS=`sw_vers -productVersion | awk -F. '{ print $2 }'`

if [ ${#} -lt 1 ]
then
  echo "Usage: ${SCRIPT_NAME} disk<ID>s<partition index>"
  echo "Example: ${SCRIPT_NAME} disk0s3"
  exit 1
fi

if [ ${SYS_VERS} -le 7 ]
then
  NTFSPROGS_VERS=7
fi

echo "Running ${SCRIPT_NAME} v${VERSION}"

TOOLS_FOLDER=`dirname "${0}"`

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
  exit 1
fi

# unmount device
echo "-> unmounting device ${NTFS_DEVICE}..."
diskutil unmount force "${NTFS_DEVICE}"

# shrinking NTFS partition
DEV_INFOS=`"${TOOLS_FOLDER}"/ntfsresize${NTFSPROGS_VERS} --info "${NTFS_DEVICE}" | grep -e "^Current volume size" -e "^Space in use"`
VOLUME_SIZE=`printf "%s\n" "${DEV_INFOS}" | grep "^Current volume size" | awk '{ print $4 }'`
SHRINK_SIZE=`printf "%s\n" "${DEV_INFOS}" | grep "^Space in use" | awk '{ print $5 }'`
USAGE=`printf "%s\n" "${DEV_INFOS}" | grep "^Space in use" | awk '{ print $7 }' | sed s/[\(\%\)]//g | awk -F. '{ print $1 }'` 
if [ -n "${VOLUME_SIZE}" ]
then
  if [ ${VOLUME_SIZE} -gt 0 ]
  then
    VOLUME_SIZE=`expr ${VOLUME_SIZE} / 1000 / 1000`
    echo "-> volume size=${VOLUME_SIZE}MB, usage=${USAGE}%"
    if [ ${USAGE} -gt 70 ]
    then
      echo "-> usage greater than 70%, volume shrinking skipped..."
    else
      if [ ${SHRINK_SIZE} -gt 0 ]
      then
	    # add 1GB to the recommanded shrinking size
        SHRINK_SIZE=`expr ${SHRINK_SIZE} + 1000`
        echo "-> testing the NTFS volume shrink on device ${NTFS_DEVICE} to ${SHRINK_SIZE}MB..."
        "${TOOLS_FOLDER}"/ntfsresize${NTFSPROGS_VERS} --size ${SHRINK_SIZE}M --no-action --force "${NTFS_DEVICE}" 2>&1
        if [ ${?} -ne 0 ]
        then
          echo "-> test failed, volume shrinking aborted..."
        else
          echo "-> shrinking the NTFS volume on device ${NTFS_DEVICE} to ${SHRINK_SIZE}MB..."
          "${TOOLS_FOLDER}"/ntfsresize${NTFSPROGS_VERS} --size ${SHRINK_SIZE}M --force "${NTFS_DEVICE}" 2>&1
          if [ ${?} -ne 0 ]
          then
            # trying to remount device
            echo "-> mounting device ${NTFS_DEVICE}..."
            diskutil mount "${NTFS_DEVICE}"

            echo "RuntimeAbortScript"
            exit 1
          fi
          # flag the device shrunk status to enable the imaging script to expand it later
          SHRUNK_FLAG=/tmp/ds_shrunk_`basename ${NTFS_DEVICE}`
          touch "${SHRUNK_FLAG}"
        fi
      else
        echo "-> invalid shrink size ${SHRINK_SIZE}MB, volume shrinking aborted..."
	  fi
    fi
  else
    echo "-> invalid volume size ${VOLUME_SIZE}MB, volume shrinking aborted..."
  fi
else
  echo "-> invalid volume size ${VOLUME_SIZE}MB, volume shrinking aborted..."
  echo "   computed from device information: ${DEV_INFOS}"
fi

# remount device
echo "-> mounting device ${NTFS_DEVICE}..."
diskutil mount "${NTFS_DEVICE}"

exit 0
