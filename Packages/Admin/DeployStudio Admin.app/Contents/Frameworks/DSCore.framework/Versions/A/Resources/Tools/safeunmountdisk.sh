#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
VERSION=1.0

if [ ${#} -lt 1 ]
then
  echo "Usage: ${SCRIPT_NAME} /dev/disk<ID>"
  echo "Example: ${SCRIPT_NAME} /dev/disk1"
  exit 1
fi

echo "Running ${SCRIPT_NAME} v${VERSION}"

ATTEMPTS=0
MAX_ATTEMPTS=15
DISKUTIL_OPTS=

if [ ! -e "${1}" ]
then
  echo "-> device not mounted..."
  echo "Exiting ${SCRIPT_NAME} v${VERSION}"
  exit 0
fi

while [ ${ATTEMPTS} -le ${MAX_ATTEMPTS} ]
do
  echo "-> unmounting device ${1}..."
  OUTPUT=`diskutil unmountDisk ${DISKUTIL_OPTS} "${1}" 2>&1`
  if [ ${?} -eq 0 ] || [[ "${OUTPUT}" =~ "successful" ]]
  then
    echo "-> unmount successful!"
    echo "Exiting ${SCRIPT_NAME} v${VERSION}"
    exit 0
  else
    echo "-> an error occured while trying to unmount the device ${1}"
    if [ -e /usr/sbin/lsof ]
    then
      echo "-> list of opened files:"
      lsof | grep "/Volumes/"
    fi
    KEXTCACHE_PID=`ps -ax | grep kextcache | grep -v grep | awk '{ print $1 }'`
    if [ -n "${KEXTCACHE_PID}" ]
    then
      kill ${KEXTCACHE_PID} 2>/dev/null
    fi
    echo "-> new attempt in 10 seconds using 'force' option..."
    sleep 10
    ATTEMPTS=`expr ${ATTEMPTS} + 1`
    DISKUTIL_OPTS=force
  fi
done

echo "-> failed to unmount device ${1}, script aborted."
echo "RuntimeAbortScript"
echo "Exiting ${SCRIPT_NAME} v${VERSION}"

exit 1
