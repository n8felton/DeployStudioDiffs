#!/bin/sh

echo "ds_partition.sh - v2.4 ("`date`")"

ARCH=`arch`
BOOT_DEVICE=`diskutil info / | grep "Device Node:" | sed s/Device\ Node://g | sed s/\ *//`
if [ "_${BOOT_DEVICE}" = "_" ]
then
  echo "RuntimeAbortWorkflow: cannot get boot device"
  echo "ds_partition.sh - end"
  exit 1
fi

SLICE_INDEX=`expr ${#BOOT_DEVICE} - 1`
while [ ${SLICE_INDEX} -ge 10 ];
do
  if [ "${BOOT_DEVICE:${SLICE_INDEX}:1}" = "s" ]
  then
	BOOT_DEVICE=${BOOT_DEVICE:0:${SLICE_INDEX}}
	break
  fi
  SLICE_INDEX=`expr ${SLICE_INDEX} - 1`
done
echo "Boot device: "${BOOT_DEVICE}

DISK_NB=0
DEVICE_FOUND=0

# The internal disk is usualy associated to the device /dev/disk0.
# The following loop looks for the first PCI-Express/PCI/SATA/SAS/ATA drive available (different from the boot drive).
# Change "-PCI-Express-SATA-SAS-ATA-" to "-FireWire-Thunderbolt-" when restoring in Target Mode or with external firewire drives.
SUPPORTED_PROTOCOLS="-PCI-Express-SATA-SAS-ATA-"
while [ ${DISK_NB} -le 20 ];
do
  TARGET_DEVICE=/dev/disk${DISK_NB}
  echo "Testing device: "${TARGET_DEVICE}
  if [ "_${BOOT_DEVICE}" = "_${TARGET_DEVICE}" ]
  then
  	echo "  -> boot drive"
  else
    PROTOCOL=`diskutil info ${TARGET_DEVICE} | grep "Protocol:" | sed s/Protocol://g | sed s/\ *//`
    if [ ! "_"`echo ${SUPPORTED_PROTOCOLS} | sed s/"-${PROTOCOL}-"//g` = "_${SUPPORTED_PROTOCOLS}" ]
	then
      RAID_MEMBER=`diskutil list ${TARGET_DEVICE} | grep "Apple_RAID"`
      if [ -z "${RAID_MEMBER}" ]
	  then
        DEVICE_FOUND=1
        break
	  else
        echo "  -> RAID set member"
	  fi
  	else
      echo "  -> non ${SUPPORTED_PROTOCOLS} drive (protocol=${PROTOCOL})"
    fi
  fi
  DISK_NB=`expr ${DISK_NB} + 1`
done

if [ "_${DEVICE_FOUND}" = "_0" ]
then
  echo "RuntimeAbortWorkflow: no internal drive available found"
  echo "ds_partition.sh - end"
  exit 1
fi

# Display the final target device
echo "Target device: "${TARGET_DEVICE}

# Find out the disk size
DISK_SIZE_INFO=`diskutil info "${TARGET_DEVICE}" | grep "Total Size:" | sed s/Total\ Size://g`
DISK_SIZE=`echo ${DISK_SIZE_INFO} | awk '{print $1}' | sed -e 's/\..//'`
DISK_SIZE_UNIT=`echo ${DISK_SIZE_INFO} | awk '{print $2}'`
if [ "${DISK_SIZE_UNIT}" = "MB" ]
then  
  DISK_SIZE_IN_BYTES=`expr \( ${DISK_SIZE} + 1 \) \* 1048576`
elif [ "${DISK_SIZE_UNIT}" = "GB" ]
then  
  DISK_SIZE_IN_BYTES=`expr \( ${DISK_SIZE} + 1 \) \* 1048576 \* 1024`
elif [ "${DISK_SIZE_UNIT}" = "TB" ]
then  
  DISK_SIZE_IN_BYTES=`expr \( ${DISK_SIZE} + 1 \) \* 1048576 \* 1048576`
fi
echo "Disk size: "${DISK_SIZE_IN_BYTES}" bytes"

# Compute the partitions size
PARTITIONS_COUNT=2

P1_SIZE=`expr ${DISK_SIZE_IN_BYTES} \* 30 / 100`
P1_NAME="System"
P1_FORMAT="Journaled HFS+"

P2_SIZE=`expr ${DISK_SIZE_IN_BYTES} - ${P1_SIZE}`
P2_NAME="Data"
P2_FORMAT="Journaled HFS+"

echo "${P1_NAME} volume size set to: ${P1_SIZE} bytes"
echo "${P2_NAME} volume size set to: ${P2_SIZE} bytes"
echo "Total: "`expr ${P1_SIZE} + ${P2_SIZE}`" bytes"

# Partition the device
echo "Unmounting device "${TARGET_DEVICE}
OUTPUT=`diskutil unmountDisk force "${TARGET_DEVICE}" 2>&1`
if [ ${?} -ne 0 ] || [[ ! "${OUTPUT}" =~ "successful" ]]
then
  echo "RuntimeAbortWorkflow: cannot unmount the device ${TARGET_DEVICE}"
  echo "ds_partition.sh - end"
  exit 1
fi

if [ "${ARCH}" = "i386" ]
then
  PartitionMapOption=GPTFormat
else
  PartitionMapOption=APMFormat
fi

echo "Partitioning disk "${TARGET_DEVICE}
diskutil partitionDisk $TARGET_DEVICE $PARTITIONS_COUNT ${PartitionMapOption} \
					   ${P1_FORMAT} "${P1_NAME}" ${P1_SIZE}B \
					   ${P2_FORMAT} "${P2_NAME}" ${P2_SIZE}B 2>&1
if [ ${?} -ne 0 ]
then
  echo "RuntimeAbortWorkflow: cannot partition the device ${TARGET_DEVICE}"
  echo "ds_partition.sh - end"
  exit 1
fi

echo "Mounting all volumes of device "${TARGET_DEVICE}
diskutil mountDisk ${TARGET_DEVICE} 2>&1
if [ ${?} -ne 0 ]
then
  echo "RuntimeAbortWorkflow: cannot mount the device ${TARGET_DEVICE}"
  echo "ds_partition.sh - end"
  exit 1
fi

echo "Give write access to all users on volume "${P2_NAME}
chown root:admin "/Volumes/${P2_NAME}" 2>&1
chmod 777 "/Volumes/${P2_NAME}" 2>&1

echo "ds_partition.sh - end"

exit 0
