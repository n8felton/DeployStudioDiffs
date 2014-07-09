#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
TOOLS_FOLDER=`dirname "${0}"`
VERSION=1.1

if [ ${#} -lt 1 ]
then
  echo "Usage: ${SCRIPT_NAME} <root path>"
  echo "Example: ${SCRIPT_NAME} /Volumes/Macintosh\ HD"
  exit 1
fi

echo "Running ${SCRIPT_NAME} v${VERSION}"

if [ ! -e "${1}" ]
then
echo "Unknown target volume ${1}, script aborted."
echo "RuntimeAbortScript"
exit 1
fi

/usr/libexec/PlistBuddy -c "Delete Sets" "${1}"/Library/Preferences/SystemConfiguration/preferences.plist 2>/dev/null
/usr/libexec/PlistBuddy -c "Delete NetworkServices" "${1}"/Library/Preferences/SystemConfiguration/preferences.plist 2>/dev/null
/usr/libexec/PlistBuddy -c "Delete VirtualNetworkInterfaces" "${1}"/Library/Preferences/SystemConfiguration/preferences.plist 2>/dev/null
/usr/libexec/PlistBuddy -c "Delete CurrentSet" "${1}"/Library/Preferences/SystemConfiguration/preferences.plist 2>/dev/null
/usr/libexec/PlistBuddy -c "Delete System:Network:BackToMyMac" "${1}"/Library/Preferences/SystemConfiguration/preferences.plist 2>/dev/null
/usr/libexec/PlistBuddy -c "Delete System:Network:BackToMyMacDSIDs" "${1}"/Library/Preferences/SystemConfiguration/preferences.plist 2>/dev/null

rm -f  "${1}"/Library/Preferences/SystemConfiguration/preferences.plist.old 2>&1
rm -f  "${1}"/Library/Preferences/SystemConfiguration/NetworkInterfaces.plist 2>&1
rm -f  "${1}"/Library/Preferences/SystemConfiguration/com.apple.NetworkInterfaces.plist 2>&1
rm -f  "${1}"/var/db/dhcpclient/* 2>&1
rm -f  "${1}"/var/db/dhcpclient/leases/* 2>&1

echo "Exiting ${SCRIPT_NAME} v${VERSION}"

exit 0