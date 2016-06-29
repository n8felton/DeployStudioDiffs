#!/bin/sh

# disable history characters
histchars=

SCRIPT_NAME=`/usr/bin/basename "${0}"`

echo "${SCRIPT_NAME} - v1.9 ("`date`")"

#
# Rename computer
#
SAFE_LOCAL_HOST_NAME=`echo "__LOCAL_HOST_NAME__" | awk -F. '{ print $1 }'`
ATTEMPTS=0
MAX_ATTEMPTS=12
while [ "_${SUCCESS}" = "_" ]
do
  if [ ${ATTEMPTS} -le ${MAX_ATTEMPTS} ]
  then
    echo "Setting local hostname to '${SAFE_LOCAL_HOST_NAME}'..." 2>&1
    /usr/sbin/scutil --set LocalHostName "${SAFE_LOCAL_HOST_NAME}"
	if [ ${?} -eq 0 ] && [ `/usr/sbin/scutil --get LocalHostName` = "${SAFE_LOCAL_HOST_NAME}" ]
    then
	  SUCCESS="YES"
    else
	  echo "An error occured while trying to rename this computer, new attempt in 10 seconds..." 2>&1
      sleep 10
      ATTEMPTS=`/bin/expr ${ATTEMPTS} + 1`
    fi
  fi
done

if [ "_${SUCCESS}" = "_YES" ]
then
  echo "Setting computer name to \"__COMPUTER_NAME__\"..." 2>&1
  /usr/sbin/scutil --set ComputerName  "__COMPUTER_NAME__"

  HOST_NAME=`/usr/sbin/scutil --get HostName 2>/dev/null`
  if [ -n "${HOST_NAME}" ]
  then
    OLD_LOCAL_HOST_NAME=`/bin/echo "${HOST_NAME}" | /usr/bin/awk -F. '{ print $1 }'`
    NEW_HOST_NAME=`/bin/echo "${HOST_NAME}" | /usr/bin/sed s/"${OLD_LOCAL_HOST_NAME}"/"${SAFE_LOCAL_HOST_NAME}"/`
    echo "Setting hostname to ${NEW_HOST_NAME}..." 2>&1
    /usr/sbin/scutil --set HostName "${NEW_HOST_NAME}"
  fi

  #
  # Self removal
  #
  rm -f "${0}"
else
  echo "Computer renaming failed, will retry on next boot!"
fi

exit 0