#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
VERSION=1.9

if [ ${#} -lt 2 ]
then
  echo "Usage: ${SCRIPT_NAME} <image file> disk<ID>s<partition index>"
  echo "Example: ${SCRIPT_NAME} image.dd[.gz] disk0s3"
  echo "RuntimeAbortScript"
  exit 1
fi

echo "Running ${SCRIPT_NAME} v${VERSION}"

IMAGE_FILE="${1}"
if [ ! -e "${IMAGE_FILE}" ]
then
  echo "File \"${IMAGE_FILE}\" not found, script aborted."
  echo "RuntimeAbortScript"
  exit 1
fi

TOOLS_FOLDER=`dirname "${0}"`

DISK_ID=`basename "${2}" | sed s/disk// | awk -Fs '{ print $1 }'`
PARTITION_ID=`basename "${2}" | sed s/disk// | awk -Fs '{ print $2 }'`

DEVICE=/dev/disk${DISK_ID}
if [ ! -e "${DEVICE}" ]
then
  echo "Unknown device ${DEVICE}, script aborted."
  echo "RuntimeAbortScript"
  exit 1
fi
RAW_DEVICE=/dev/rdisk${DISK_ID}

# get the starting block value from the MBR
if [ -e "${TOOLS_FOLDER}"/fdisk ] && [ `sw_vers -productVersion | awk -F. '{ print $2 }'` -gt 5 ]
then
  FDISK="${TOOLS_FOLDER}"/fdisk
else
  FDISK=fdisk
fi
STARTING_BLOCK=`"${FDISK}" -d "${RAW_DEVICE}" | head -n${PARTITION_ID} | tail -n1 | awk -F, '{ print $1 }'`
if [ -z "${STARTING_BLOCK}" ] || [ "${STARTING_BLOCK}" -le 0 ]
then
  echo "-> invalid starting block value (${STARTING_BLOCK}) defined in MBR for partition ${NTFS_DEVICE}."
  echo "   Check your partition map. You need to define at least one DOS/FAT partition in order to get the MBR automatically in sync with GPT."
  echo "RuntimeAbortScript"
  exit 1
fi

# unmount device
"${TOOLS_FOLDER}"/safeunmountdisk.sh "${DEVICE}"

# compressed files
COMPRESSED=`echo ${1} | grep -i "\.gz$"`

# restore the MBR bootstrap code
BOOTSTRAP_FILE=`echo "${1}" | sed s/"\\.dd"/"\\.bootstrap"/ | sed s/"\\.gz$"//`
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

# ensure device is still unmounted after MBR restoration
"${TOOLS_FOLDER}"/safeunmountdisk.sh "${DEVICE}"

# restore device partition
echo "-> restoring device partition (${IMAGE_FILE})..."
if [ -n "${COMPRESSED}" ]
then
  gunzip -c "${IMAGE_FILE}" | dd of="${DEVICE}s${PARTITION_ID}" bs=16384k &>/tmp/${$}.log &
else
  dd if="${IMAGE_FILE}" of="${DEVICE}s${PARTITION_ID}" bs=16384k &>/tmp/${$}.log &
fi
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

# updating MBR partition table
echo "-> updating MBR partition table (partition ${PARTITION_ID})"
FS_ID_FILE=`echo "${1}" | sed s/"\\.dd"/"\\.id"/ | sed s/"\\.gz$"//`
if [ -e "${FS_ID_FILE}" ]
then
  FS_ID=`cat "${FS_ID_FILE}" | head -n 1`
  let FS_ID_INT=0x${FS_ID}
  if [ ${FS_ID_INT} -gt 0 ] && [ ${FS_ID_INT} -le 255 ]
  then
    echo "   with saved file system id 0x${FS_ID}"
  else
    FS_ID=83
  fi
else
  FS_ID=83
fi
printf "setpid ${PARTITION_ID}\n${FS_ID}\nflag ${PARTITION_ID}\nwrite\ny\nquit\n" | fdisk -e "${RAW_DEVICE}"

# MBR partition table sync
#echo "-> syncing MBR partition table on device ${DEVICE}..."
#"${TOOLS_FOLDER}"/gptrefresh -vwf "${DEVICE}"

# remount device
echo "-> mounting device ${DEVICE}..."
diskutil mountDisk "${DEVICE}"
if [ ${?} -ne 0 ]
then
  IDX=2
  while [ -e "${DEVICE}s${IDX}" ]
  do
    diskutil mount "${DEVICE}s${IDX}" &>/dev/null
    IDX=`expr ${IDX} + 1`
  done
fi

exit 0
