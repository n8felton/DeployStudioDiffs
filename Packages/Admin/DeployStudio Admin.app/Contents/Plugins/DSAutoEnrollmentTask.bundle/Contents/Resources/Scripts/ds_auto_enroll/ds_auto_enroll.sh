#!/bin/sh

# disable history characters
histchars=

SCRIPT_NAME=`/usr/bin/basename "${0}"`

echo "${SCRIPT_NAME} - v1.2 ("`date`")"

SSL_FILE=`echo "${0}" | sed s/\.sh$/_ssl\.mobileconfig/`
BOOTSTRAP_FILE=`echo "${0}" | sed s/\.sh$/_bootstrap\.mobileconfig/`

#
# Import trust profile first
#
if [ -e "${SSL_FILE}" ]
then
  echo "Importing trust profile '${SSL_FILE}'"
  profiles -I -F "${SSL_FILE}"
  if [ ${?} -ne 0 ]
  then
    echo "Trust profile import failed, will retry on next boot!"
    exit 1
  fi
fi

#
# Import enrollment profile
#
if [ -e "${BOOTSTRAP_FILE}" ]
then
  echo "Importing enrollment profile '${BOOTSTRAP_FILE}'"
  profiles -I -F "${BOOTSTRAP_FILE}"
  if [ ${?} -ne 0 ]
  then
    echo "Enrollment profile import failed, will retry on next boot!"
    exit 1
  fi
fi

#
# Self removal
#
rm -f "${0}"

exit 0