#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
VERSION=1.0

########################################################
# Main
########################################################

if [ -n "${1}" ] && [ -d "${1}" ]
then
  BASE_SYS_VERS=`defaults read "${1}"/System/Library/CoreServices/SystemVersion ProductVersion 2>/dev/null`
elif [ -n "${1}" ] && [ -d "/Volumes/${1}" ]
then
  BASE_SYS_VERS=`defaults read /Volumes/"${1}"/System/Library/CoreServices/SystemVersion ProductVersion 2>/dev/null`
else
  BASE_SYS_VERS=`sw_vers -productVersion`
fi
BOOT_MAJOR_SYS_VERS=`echo ${BASE_SYS_VERS} | awk -F. '{ print $2 }'`
BEST_RECOVERY_DEVICE=
BEST_RECOVERY_DEVICE_SYS_VERS=
BEST_RECOVERY_DEVICE_MINOR_SYS_VERS=0

if [ -e "/Volumes/Recovery HD/com.apple.recovery.boot/SystemVersion.plist" ]
then
  RECOVERY_SYS_VERS=`defaults read /Volumes/Recovery\ HD/com.apple.recovery.boot/SystemVersion ProductVersion 2>/dev/null`
  if [ "${BASE_SYS_VERS}" == "${RECOVERY_SYS_VERS}" ]
  then
    echo "${BASE_SYS_VERS}:/dev/"`diskutil info "/Volumes/Recovery HD" | grep "Device Identifier:" | sed s/.*Device\ Identifier:\ *//`
    exit 0
  else
    RECOVERY_MAJOR_SYS_VERS=`echo ${RECOVERY_SYS_VERS} | awk -F. '{ print $2 }'`
    RECOVERY_MINOR_SYS_VERS=`echo ${RECOVERY_SYS_VERS} | awk -F. '{ print $3 }'`
    if [ -z "${RECOVERY_MINOR_SYS_VERS}" ]
    then
      RECOVERY_MINOR_SYS_VERS=0
    fi
    if [ "${BOOT_MAJOR_SYS_VERS}" == "${RECOVERY_MAJOR_SYS_VERS}" ] && [ "${RECOVERY_MINOR_SYS_VERS}" -ge "${BEST_RECOVERY_DEVICE_MINOR_SYS_VERS}" ]
    then
      BEST_RECOVERY_DEVICE=/dev/`diskutil info "/Volumes/Recovery HD" | grep "Device Identifier:" | sed s/.*Device\ Identifier:\ *//`
      BEST_RECOVERY_DEVICE_SYS_VERS=${RECOVERY_SYS_VERS}
      BEST_RECOVERY_DEVICE_MINOR_SYS_VERS=${RECOVERY_MINOR_SYS_VERS}
    fi
  fi
  diskutil unmount force "/Volumes/Recovery HD" >/dev/null 2>&1
fi

RECOVERY_HD_DEVICES=`diskutil list | grep -E "Apple_Boot.*Recovery HD" | awk '{ print $(NF) }'`
for RECOVERY_HD_DEVICE in ${RECOVERY_HD_DEVICES}
do
  if [ -n "${RECOVERY_HD_DEVICE}" ] && [ -e "/dev/${RECOVERY_HD_DEVICE}" ]
  then
    diskutil mount readOnly "/dev/${RECOVERY_HD_DEVICE}" >/dev/null 2>&1
    if [ ${?} -eq 0 ]
    then
      RECOVERY_SYS_VERS=`defaults read /Volumes/Recovery\ HD/com.apple.recovery.boot/SystemVersion ProductVersion 2>/dev/null`
      diskutil unmount "/dev/${RECOVERY_HD_DEVICE}" >/dev/null 2>&1
      if [ ${?} -ne 0 ]
      then
        diskutil unmount force "/dev/${RECOVERY_HD_DEVICE}" >/dev/null 2>&1
      fi
      if [ "${BASE_SYS_VERS}" == "${RECOVERY_SYS_VERS}" ]
	  then
	    echo "${BASE_SYS_VERS}:/dev/${RECOVERY_HD_DEVICE}"
	    exit 0
	  else
		RECOVERY_MAJOR_SYS_VERS=`echo ${RECOVERY_SYS_VERS} | awk -F. '{ print $2 }'`
		RECOVERY_MINOR_SYS_VERS=`echo ${RECOVERY_SYS_VERS} | awk -F. '{ print $3 }'`
		if [ -z "${RECOVERY_MINOR_SYS_VERS}" ]
		then
		  RECOVERY_MINOR_SYS_VERS=0
		fi
		if [ "${BOOT_MAJOR_SYS_VERS}" == "${RECOVERY_MAJOR_SYS_VERS}" ] && [ "${RECOVERY_MINOR_SYS_VERS}" -ge "${BEST_RECOVERY_DEVICE_MINOR_SYS_VERS}" ]
		then
		  BEST_RECOVERY_DEVICE=/dev/${RECOVERY_HD_DEVICE}
		  BEST_RECOVERY_DEVICE_SYS_VERS=${RECOVERY_SYS_VERS}
		  BEST_RECOVERY_DEVICE_MINOR_SYS_VERS=${RECOVERY_MINOR_SYS_VERS}
	    fi
	  fi
    fi
  fi
done

if [ -n "${BEST_RECOVERY_DEVICE_SYS_VERS}" ] && [ -n "${BEST_RECOVERY_DEVICE}" ]
then
  echo "${BEST_RECOVERY_DEVICE_SYS_VERS}:${BEST_RECOVERY_DEVICE}"
  exit 0
fi

exit 1