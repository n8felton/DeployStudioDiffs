#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
TOOLS_FOLDER=`dirname "${0}"`
VERSION=1.29

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

rm -f  "${1}"/Library/LaunchAgents/com.deploystudio.FinalizeApp.plist 2>/dev/null
rm -f  "${1}"/Library/LaunchAgents/com.deploystudio.finalizeCleanup.plist 2>/dev/null
rm -f  "${1}"/Library/LaunchAgents/com.deploystudio.finalizeScript.plist 2>/dev/null
rm -f  "${1}"/Library/LaunchDaemons/com.deploystudio.FinalizeApp.plist 2>/dev/null
rm -f  "${1}"/Library/LaunchDaemons/com.deploystudio.finalizeCleanup.plist 2>/dev/null
rm -f  "${1}"/Library/LaunchDaemons/com.deploystudio.finalizeScript.plist 2>/dev/null
rm -rf "${1}"/etc/deploystudio 2>/dev/null

rm -f  "${1}"/Library/Keychains/apsd.keychain 2>/dev/null
rm -f  "${1}"/private/var/db/ConfigurationProfiles/.cloudConfig*           2>/dev/null
rm -f  "${1}"/private/var/db/ConfigurationProfiles/.*ActivationRecord      2>/dev/null
rm -f  "${1}"/private/var/db/ConfigurationProfiles/.passcode*              2>/dev/null
rm -f  "${1}"/private/var/db/ConfigurationProfiles/.profiles*              2>/dev/null
rm -f  "${1}"/private/var/db/ConfigurationProfiles/Setup/.profileSetupDone 2>/dev/null

rm -rf "${1}"/.DocumentRevisions-V100 2>/dev/null
rm -rf "${1}"/.MobileBackups 2>/dev/null
rm -rf "${1}"/.Spotlight-V100 2>/dev/null
rm -rf "${1}"/.Trashes 2>/dev/null

rm -f  "${1}/Desktop DB" 2>/dev/null
rm -f  "${1}/Desktop DF" 2>/dev/null
#/usr/libexec/PlistBuddy -c "Delete Sets" "${1}"/Library/Preferences/SystemConfiguration/preferences.plist 2>/dev/null
#/usr/libexec/PlistBuddy -c "Delete NetworkServices" "${1}"/Library/Preferences/SystemConfiguration/preferences.plist 2>/dev/null
#/usr/libexec/PlistBuddy -c "Delete VirtualNetworkInterfaces" "${1}"/Library/Preferences/SystemConfiguration/preferences.plist 2>/dev/null
#/usr/libexec/PlistBuddy -c "Delete CurrentSet" "${1}"/Library/Preferences/SystemConfiguration/preferences.plist 2>/dev/null
/usr/libexec/PlistBuddy -c "Delete System:Network:BackToMyMac" "${1}"/Library/Preferences/SystemConfiguration/preferences.plist 2>/dev/null
/usr/libexec/PlistBuddy -c "Delete System:Network:BackToMyMacDSIDs" "${1}"/Library/Preferences/SystemConfiguration/preferences.plist 2>/dev/null
rm -f  "${1}"/Library/Preferences/SystemConfiguration/preferences.plist.old 2>/dev/null
rm -f  "${1}"/Library/Preferences/SystemConfiguration/NetworkInterfaces.plist 2>/dev/null
rm -f  "${1}"/Library/Preferences/SystemConfiguration/com.apple.NetworkInterfaces.plist 2>/dev/null
rm -f  "${1}"/Library/Preferences/com.apple.Bluetooth.plist 2>/dev/null
rm -rf "${1}"/System/Library/Caches/* 2>/dev/null
rm -f  "${1}"/System/Library/Extensions.kextcache 2>/dev/null
rm -f  "${1}"/System/Library/Extensions.mkext 2>/dev/null
rm -f  "${1}"/private/var/db/BootCache.playlist 2>/dev/null
rm -f  "${1}"/private/var/db/NetworkInterfaces.xml 2>/dev/null
rm -f  "${1}"/private/var/db/volinfo.database 2>/dev/null
rm -f  "${1}"/private/var/db/dhcpclient/* 2>/dev/null
rm -f  "${1}"/private/var/db/dhcpclient/leases/* 2>/dev/null
rm -f  "${1}"/private/var/db/dyld/dyld* 2>/dev/null
rm -f  "${1}"/private/var/pcast/server/krb_cc 2>/dev/null
rm -f  "${1}"/private/var/vm/sleepimage 2>/dev/null
rm -f  "${1}"/private/var/log/ds_finalize.log 2>/dev/null

if [ ! -e "${1}"/private/var/db/.AppleSetupDone ]
then
  rm -f "${1}"/private/var/db/.AppleSetup*
  touch "${1}"/private/var/db/.RunLanguageChooserToo
fi

if [ -e "${1}"/Library/Filesystems/Xsan/config/uuid ]
then
  uuidgen > "${1}"/Library/Filesystems/Xsan/config/uuid
  chmod 644 "${1}"/Library/Filesystems/Xsan/config/uuid
  chown root:wheel "${1}"/Library/Filesystems/Xsan/config/uuid
fi
if [ -e "${1}"/Library/Preferences/Xsan/uuid ]
then
  HOSTUUID=`ioreg -rd1 -c IOPlatformExpertDevice | awk -F= '/(UUID)/ { gsub("[ \"]", ""); print $2 }'`
  if [ -n "${HOSTUUID}" ]
  then
    echo "${HOSTUUID}" > "${1}"/Library/Preferences/Xsan/uuid
    chmod 600 "${1}"/Library/Preferences/Xsan/uuid
    chown root:wheel "${1}"/Library/Preferences/Xsan/uuid
  else
    rm "${1}"/Library/Preferences/Xsan/uuid 2>/dev/null
  fi
fi

if [ -e "${1}"/System/Library/CoreServices/SystemVersion.plist ] && [ ! -e "${1}"/System/Library/CoreServices/ServerVersion.plist ] && [ -e "${1}"/usr/libexec/configureLocalKDC ]
then
  rm -rf "${1}/Library/Preferences/OpenDirectory/Configurations/Active Directory" 2>/dev/null
  rm -rf "${1}/Library/Preferences/OpenDirectory/DynamicData/Active Directory" 2>/dev/null
  rm -rf "${1}"/Library/Preferences/DirectoryService/ActiveDirectory.plist 2>/dev/null
  rm -f  "${1}"/private/var/db/dslocal/nodes/Default/config/KerberosKDC.plist 2>/dev/null
  "${TOOLS_FOLDER}"/deleteKeychainCert "${1}"/Library/Keychains/System.keychain com.apple.kerberos.kdc
  "${TOOLS_FOLDER}"/deleteKeychainCert "${1}"/Library/Keychains/System.keychain com.apple.systemdefault
  rm -f  "${1}"/etc/krb5.keytab 2>/dev/null
  rm -rf "${1}"/private/var/db/krb5kdc 2>/dev/null
fi

echo "Exiting ${SCRIPT_NAME} v${VERSION}"

exit 0