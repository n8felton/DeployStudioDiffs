#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
VERSION=1.1

if [ ${#} -lt 3 ]
then
  echo "Usage: ${SCRIPT_NAME} <format> <disk image path> <output path>"
  echo "Example: ${SCRIPT_NAME} UDZO /tmp/diskimage.rw.dmg /tmp/diskimage.compressed.dmg"
  exit 1
fi

echo "Running ${SCRIPT_NAME} v${VERSION}"

TRIES=1
SLEEP_DURATION=30

echo "/usr/bin/hdiutil convert -puppetstrings -format ${1} -o \"${3}\" \"${2}\""
/usr/bin/hdiutil convert -puppetstrings -format ${1} -o "${3}" "${2}" 2>&1

while [ ${?} -ne 0 ];
do
  TRIES=`expr ${TRIES} + 1` 
  if [ ${TRIES} -gt 30 ]
  then
    echo "Failed to convert \"${2}\", aborting..."
    echo "Exiting ${SCRIPT_NAME} v${VERSION}"
    exit 1
  fi
  echo "An error occured while converting \"${3}\", retrying in ${SLEEP_DURATION} seconds..."
  sleep ${SLEEP_DURATION}
  echo "/usr/bin/hdiutil convert -puppetstrings -format ${1} -o \"${3}\" \"${2}\""
  /usr/bin/hdiutil convert -puppetstrings -format ${1} -o "${3}" "${2}" 2>&1
done

echo "Exiting ${SCRIPT_NAME} v${VERSION}"

exit 0
