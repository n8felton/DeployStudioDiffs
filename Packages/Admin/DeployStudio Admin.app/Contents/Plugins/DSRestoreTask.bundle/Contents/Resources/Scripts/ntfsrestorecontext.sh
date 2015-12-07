#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
VERSION=2.21
SYS_VERS=`sw_vers -productVersion | awk -F. '{ print $2 }'`

if [ ${#} -lt 2 ]
then
  echo "Usage: ${SCRIPT_NAME} <image file> disk<ID>s<partition index> [--addgenericbcd]"
  echo "Example: ${SCRIPT_NAME} image.ntfs[.gz|.dmg] disk0s3"
  echo "RuntimeAbortScript"
  exit 1
fi

if [ ${SYS_VERS} -le 7 ]
then
  NTFSPROGS_VERS=7
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

NTFS_DEVICE=${DEVICE}s${PARTITION_ID}
if [ ! -e "${NTFS_DEVICE}" ]
then
  echo "Unknown device ${NTFS_DEVICE}, script aborted."
  echo "RuntimeAbortScript"
  exit 1
fi

# add generic BCD
if [ -n "${3}" ] && [ "${3}" = "--addgenericbcd" ]
then
  ADD_GENERIC_BCD="YES"
elif [ -n "${4}" ] && [ "${4}" = "--addgenericbcd" ]
then
  ADD_GENERIC_BCD="YES"
else
  ADD_GENERIC_BCD="NO"
fi

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

# restore the MBR bootstrap code
BOOTSTRAP_FILE=`echo "${1}" | sed s/"\\.ntfs"/"\\.bootstrap"/ | sed s/"\\.gz$"// | sed s/"\\.dmg$"//`
if [ -e "${BOOTSTRAP_FILE}.gz" ]
then
  echo "-> uncompressing MBR bootstrap code (${BOOTSTRAP_FILE}.gz)..."
  gunzip "${BOOTSTRAP_FILE}.gz"
fi
if [ -e "${BOOTSTRAP_FILE}" ]
then
  echo "-> restoring MBR bootstrap code (${BOOTSTRAP_FILE})..."
  dd if="${BOOTSTRAP_FILE}" of="${DEVICE}" bs=446 count=1
else
  echo "-> MBR bootstrap code not found, aborting..."
  echo "RuntimeAbortScript"
  exit 1
fi 

# ensure device is still unmounted
"${TOOLS_FOLDER}"/safeunmountdisk.sh "${DEVICE}"

# update windows boot config files
BOOT_CONFIG_FILE=`echo "${1}" | sed s/"\\.ntfs"/"\\.bcd"/ | sed s/"\\.gz$"// | sed s/"\\.dmg$"//`
if [ -e "${BOOT_CONFIG_FILE}" ]
then
  if [ "${ADD_GENERIC_BCD}" = "YES" ]
  then
    if [ -e "${TOOLS_FOLDER}/ms.deviceboot.bcd" ]
    then
      # ms.deviceboot.bcd (/Boot/BCD) was copied from Windows (Vista/7) after running the following commands
      # > bcdedit /set {bootmgr} device boot
      # > bcdedit /set {default} device boot
      # > bcdedit /set {default} osdevice boot
      echo "-> restoring generic BCD boot config (${TOOLS_FOLDER}/ms.deviceboot.bcd)..."
      "${TOOLS_FOLDER}"/ntfscp${NTFSPROGS_VERS} -f "${NTFS_DEVICE}" "${TOOLS_FOLDER}/ms.deviceboot.bcd" /Boot/BCD
    else
      echo "-> restoring BCD boot config (${BOOT_CONFIG_FILE})..."
      "${TOOLS_FOLDER}"/ntfscp${NTFSPROGS_VERS} -f "${NTFS_DEVICE}" "${BOOT_CONFIG_FILE}" /Boot/BCD
    fi
  fi
else
  echo "-> ${BOOT_CONFIG_FILE} file not found..."
  BOOT_CONFIG_FILE=`echo "${1}" | sed s/"\\.ntfs"/"\\.ini"/ | sed s/"\\.gz$"// | sed s/"\\.dmg$"//`
  if [ -e "${BOOT_CONFIG_FILE}" ]
  then
	cat "${BOOT_CONFIG_FILE}" | sed s/partition\(.\)/partition\(${PARTITION_ID}\)/ > /tmp/boot.ini
	if [ -e "/tmp/boot.ini" ]
	then
	  NEEDS_UPDATE=`diff "${BOOT_CONFIG_FILE}" /tmp/boot.ini`
	  if [ -n "${NEEDS_UPDATE}" ]
	  then
        echo "-> updating boot.ini file (/tmp/boot.ini)..."
        "${TOOLS_FOLDER}"/ntfscp${NTFSPROGS_VERS} -f "${NTFS_DEVICE}" "/tmp/boot.ini" boot.ini
      else
        echo "-> boot.ini file is correct, no fix needed."
	  fi
	else
	  echo "-> customized boot.ini file not found (/tmp/boot.ini)..."
	fi
  else
    echo "-> ${BOOT_CONFIG_FILE} file not found..."
  fi
fi
if [ ${?} -ne 0 ]
then
  echo "RuntimeAbortScript"
  exit 1
fi

#echo "-> emptying pagefile.sys config file..."
#touch "/tmp/pagefile.sys"
#"${TOOLS_FOLDER}"/ntfscp${NTFSPROGS_VERS} -f "${NTFS_DEVICE}" "/tmp/pagefile.sys" pagefile.sys
#if [ ${?} -ne 0 ]
#then
#  echo "RuntimeAbortScript"
#  exit 1
#fi

# sysprep file lookup
echo "-> looking for sysprep configuration files..."
SYSPREP_FILE=""
"${TOOLS_FOLDER}"/ntfscat${NTFSPROGS_VERS} -f "${NTFS_DEVICE}" /SysPrep/SYSPREP.INF > /tmp/SYSPREP.INF
if [ ${?} -eq 0 ]
then
  SYSPREP_FILE=/SysPrep/SYSPREP.INF
else
  "${TOOLS_FOLDER}"/ntfscat${NTFSPROGS_VERS} -f "${NTFS_DEVICE}" /windows/panther/unattend.XML > /tmp/unattend.xml
  if [ ${?} -eq 0 ]
  then
    SYSPREP_FILE=/windows/panther/unattend.XML
  else
    "${TOOLS_FOLDER}"/ntfscat${NTFSPROGS_VERS} -f "${NTFS_DEVICE}" /windows/system32/sysprep/unattend.xml > /tmp/unattend.xml
    if [ ${?} -eq 0 ]
    then
      SYSPREP_FILE=/windows/system32/sysprep/unattend.xml
    fi
  fi
fi

# update sysprep's file ComputerName attribute
if [ -n "${SYSPREP_FILE}" ] && [ -n "${DS_BOOTCAMP_WINDOWS_COMPUTER_NAME}" ]
then
  if [ `basename "${SYSPREP_FILE}"` = "SYSPREP.INF" ]
  then
    INF_SYSPREP_COMPUTERNAME=`grep -i -m 1 "ComputerName=" /tmp/SYSPREP.INF | tr -d " \n\r" | sed s/'*'/'\\\*'/`
    if [ -n "${INF_SYSPREP_COMPUTERNAME}" ]
    then
      sed s%"${INF_SYSPREP_COMPUTERNAME}"%"ComputerName=${DS_BOOTCAMP_WINDOWS_COMPUTER_NAME}"% /tmp/SYSPREP.INF > /tmp/SYSPREP.INF.NEW
      echo "-> updating computer name in ${SYSPREP_FILE} to ${DS_BOOTCAMP_WINDOWS_COMPUTER_NAME}..."
      "${TOOLS_FOLDER}"/ntfscp${NTFSPROGS_VERS} -f "${NTFS_DEVICE}" /tmp/SYSPREP.INF.NEW "${SYSPREP_FILE}"
      if [ ${?} -ne 0 ]
      then
        echo "RuntimeAbortScript"
        exit 1
      fi
    fi
  else
    XML_SYSPREP_COMPUTERNAME=`grep -i -m 1 "<ComputerName>.*</ComputerName>" /tmp/unattend.xml | tr -d " \n\r" | sed s/'*'/'\\\*'/ | awk -F"ComputerName" '{ print $2 }'`
    if [ -n "${XML_SYSPREP_COMPUTERNAME}" ]
    then
      sed s%"${XML_SYSPREP_COMPUTERNAME}"%">${DS_BOOTCAMP_WINDOWS_COMPUTER_NAME}</"% /tmp/unattend.xml > /tmp/unattend.xml.NEW
      echo "-> updating computer name in ${SYSPREP_FILE} to ${DS_BOOTCAMP_WINDOWS_COMPUTER_NAME}..."
      "${TOOLS_FOLDER}"/ntfscp${NTFSPROGS_VERS} -f "${NTFS_DEVICE}" /tmp/unattend.xml.NEW "${SYSPREP_FILE}"
      if [ ${?} -ne 0 ]
      then
        echo "RuntimeAbortScript"
        exit 1
      fi
    fi
  fi
fi 

# update sysprep's file ProductKey attribute
if [ -n "${SYSPREP_FILE}" ] && [ -n "${DS_BOOTCAMP_WINDOWS_PRODUCT_KEY}" ]
then
  if [ `basename "${SYSPREP_FILE}"` = "SYSPREP.INF" ]
  then
    "${TOOLS_FOLDER}"/ntfscat${NTFSPROGS_VERS} -f "${NTFS_DEVICE}" "${SYSPREP_FILE}" > /tmp/SYSPREP.INF
    INF_SYSPREP_PRODUCT_KEY=`grep -m 1 "ProductKey=" /tmp/SYSPREP.INF | tr -d " \n\r" | sed s/'*'/'\\\*'/`
    if [ -n "${INF_SYSPREP_PRODUCT_KEY}" ]
    then
      sed s%"${INF_SYSPREP_PRODUCT_KEY}"%"ProductKey=${DS_BOOTCAMP_WINDOWS_PRODUCT_KEY}"% /tmp/SYSPREP.INF > /tmp/SYSPREP.INF.NEW
      echo "-> updating product key in ${SYSPREP_FILE} to ${DS_BOOTCAMP_WINDOWS_PRODUCT_KEY}..."
      "${TOOLS_FOLDER}"/ntfscp${NTFSPROGS_VERS} -f "${NTFS_DEVICE}" /tmp/SYSPREP.INF.NEW "${SYSPREP_FILE}"
      if [ ${?} -ne 0 ]
      then
        echo "RuntimeAbortScript"
        exit 1
      fi
    fi
  else
    "${TOOLS_FOLDER}"/ntfscat${NTFSPROGS_VERS} -f "${NTFS_DEVICE}" "${SYSPREP_FILE}" > /tmp/unattend.xml
    XML_SYSPREP_PRODUCT_KEY=`grep -m 1 "<ProductKey>.*</ProductKey>" /tmp/unattend.xml | tr -d " \n\r" | sed s/'*'/'\\\*'/ | awk -F"ProductKey" '{ print $2 }'`
    if [ -n "${XML_SYSPREP_PRODUCT_KEY}" ]
    then
      sed s%"${XML_SYSPREP_PRODUCT_KEY}"%">${DS_BOOTCAMP_WINDOWS_PRODUCT_KEY}</"% /tmp/unattend.xml > /tmp/unattend.xml.NEW
      echo "-> updating product key in ${SYSPREP_FILE} to ${DS_BOOTCAMP_WINDOWS_PRODUCT_KEY}..."
      "${TOOLS_FOLDER}"/ntfscp${NTFSPROGS_VERS} -f "${NTFS_DEVICE}" /tmp/unattend.xml.NEW "${SYSPREP_FILE}"
      if [ ${?} -ne 0 ]
      then
        echo "RuntimeAbortScript"
        exit 1
      fi
    fi
  fi
fi 

# update MBR partition table
echo "-> updating MBR partition table (partition ${PARTITION_ID})"
FS_ID_FILE=`echo "${1}" | sed s/"\\.ntfs"/"\\.id"/ | sed s/"\\.gz$"// | sed s/"\\.dmg$"//`
if [ -e "${FS_ID_FILE}" ]
then
  FS_ID=`cat "${FS_ID_FILE}" | head -n 1`
  let FS_ID_INT=0x${FS_ID}
  if [ ${FS_ID_INT} -gt 0 ] && [ ${FS_ID_INT} -le 255 ]
  then
    echo "   with saved file system id 0x${FS_ID}"
  else
    FS_ID=7
  fi
else
  FS_ID=7
fi
printf "setpid ${PARTITION_ID}\n${FS_ID}\nflag ${PARTITION_ID}\nwrite\nquit\n" | fdisk -y -e "${RAW_DEVICE}"
echo

# update partition geometry
HEX_INDEX=`printf "%08x" ${STARTING_BLOCK}`
RHEX_INDEX=${HEX_INDEX:6:2}${HEX_INDEX:4:2}${HEX_INDEX:2:2}${HEX_INDEX:0:2}
echo "-> updating NTFS partition geometry (starting block=${STARTING_BLOCK}/${HEX_INDEX}/${RHEX_INDEX})..."
echo ${RHEX_INDEX} | xxd -r -p | dd conv=notrunc of="${NTFS_DEVICE}" bs=1 seek=28

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
