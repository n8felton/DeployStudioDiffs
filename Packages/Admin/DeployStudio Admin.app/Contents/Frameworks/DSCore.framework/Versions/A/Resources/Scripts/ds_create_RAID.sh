#!/bin/sh

SCRIPT_NAME=`basename "${0}"`

echo "${SCRIPT_NAME} - v2.4 ("`date`")"

BOOT_DEVICE=`diskutil info / | grep "Device Node:" | sed s/Device\ Node://g | sed s/\ *//`
if [ "_${BOOT_DEVICE}" = "_" ]
then
  echo "RuntimeAbortWorkflow: cannot get boot device"
  echo "${SCRIPT_NAME} - end"
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
SET_SIZE=0

# The internal disk is usualy associated to the device /dev/disk0.
# The following loop looks for all PCI-Express/PCI/SATA/SAS/ATA drives available (different from the boot drive).
# These drives will all be added to the RAID that will be created.
# A minimum of 2 disks is reauired.
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
        SET_SIZE=`expr ${SET_SIZE} + 1`
        DEVICES_SET="${DEVICES_SET} ${TARGET_DEVICE}"
        echo "Unmounting device "${TARGET_DEVICE}
		OUTPUT=`diskutil unmountDisk force "${TARGET_DEVICE}" 2>&1`
		if [ ${?} -ne 0 ] || [[ ! "${OUTPUT}" =~ "successful" ]]
		then
           echo "RuntimeAbortWorkflow: cannot unmount the device ${TARGET_DEVICE}"
           echo "${SCRIPT_NAME} - end"
           exit 1
        fi
      else
        echo "  -> RAID set member"
      fi
    else
      echo "  -> non ${SUPPORTED_PROTOCOLS} drive (protocol=${PROTOCOL})"
    fi
  fi
  DISK_NB=`expr ${DISK_NB} + 1`
done

if [ ${SET_SIZE} -lt 2 ]
then
  echo "RuntimeAbortWorkflow: less than 2 available internal drives found"
  echo "${SCRIPT_NAME} - end"
  exit 1
fi

if [ -z "${DEVICES_SET}" ]
then
  echo "RuntimeAbortWorkflow: no internal drive available found"
  echo "${SCRIPT_NAME} - end"
  exit 1
fi

# Display the final target devices
echo "Target devices: "${DEVICES_SET}

RAID_TYPE=stripe
RAID_NAME="Macintosh HD"
RAID_FORMAT="Journaled HFS+"

echo "Creating RAID with devices "${DEVICES_SET}
diskutil createRAID ${RAID_TYPE} "${RAID_NAME}" ${RAID_FORMAT} ${DEVICES_SET} 2>&1
if [ ${?} -ne 0 ]
then
  echo "RuntimeAbortWorkflow: cannot create RAID from devices ${DEVICES_SET}"
  echo "${SCRIPT_NAME} - end"
  exit 1
fi

echo "${SCRIPT_NAME} - end"

exit 0
