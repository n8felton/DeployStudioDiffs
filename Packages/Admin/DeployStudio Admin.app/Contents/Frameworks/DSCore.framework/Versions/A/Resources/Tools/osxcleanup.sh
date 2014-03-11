#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
TOOLS_FOLDER=`dirname "${0}"`
VERSION=1.20

if [ ${#} -lt 2 ]
then
  echo "Usage: ${SCRIPT_NAME} -preimaging | -postrestoration <root path>"
  echo "Example: ${SCRIPT_NAME} -preimaging /Volumes/Macintosh\ HD"
  exit 1
fi

echo "Running ${SCRIPT_NAME} v${VERSION}"

rm -f  "${2}"/Library/LaunchAgents/com.deploystudio.FinalizeApp.plist 2>/dev/null
rm -f  "${2}"/Library/LaunchAgents/com.deploystudio.finalizeCleanup.plist 2>/dev/null
rm -f  "${2}"/Library/LaunchAgents/com.deploystudio.finalizeScript.plist 2>/dev/null
rm -f  "${2}"/Library/LaunchDaemons/com.deploystudio.FinalizeApp.plist 2>/dev/null
rm -f  "${2}"/Library/LaunchDaemons/com.deploystudio.finalizeCleanup.plist 2>/dev/null
rm -f  "${2}"/Library/LaunchDaemons/com.deploystudio.finalizeScript.plist 2>/dev/null
rm -rf "${2}"/etc/deploystudio 2>/dev/null

if [ "${1}" == "-preimaging" ]
then
  rm -f  "${2}"/Library/LaunchDaemons/com.deploystudio.freezeHomedirs.plist 2>&1
  rm -f  "${2}"/usr/local/sbin/ds_freeze_homedirs.sh 2>&1
  rm -rf "${2}"/private/dss_homedirs_ref 2>&1
  rm -f  "${2}"/var/vm/sleepimage 2>&1
  rm -f  "${2}"/var/vm/swapfile* 2>&1
  rm -rf "${2}"/System/Library/Caches/* 2>&1
  rm -f  "${2}"/var/log/ds_finalize.log 2>&1
elif [ "${1}" == "-postrestoration" ]
then
  rm -f  "${2}/Desktop DB" 2>&1
  rm -f  "${2}/Desktop DF" 2>&1
  rm -f  "${2}"/Library/Preferences/SystemConfiguration/NetworkInterfaces.plist 2>&1
  rm -f  "${2}"/Library/Preferences/SystemConfiguration/com.apple.NetworkInterfaces.plist 2>&1
  rm -f  "${2}"/Library/Preferences/com.apple.Bluetooth.plist 2>&1
  rm -rf "${2}"/System/Library/Caches/* 2>&1
  rm -f  "${2}"/System/Library/Extensions.kextcache 2>&1
  rm -f  "${2}"/System/Library/Extensions.mkext 2>&1
  rm -f  "${2}"/private/var/db/BootCache.playlist 2>&1
  rm -f  "${2}"/private/var/db/NetworkInterfaces.xml 2>&1
  rm -f  "${2}"/private/var/db/volinfo.database 2>&1
  rm -f  "${2}"/var/db/dhcpclient/leases/* 2>&1
  rm -f  "${2}"/var/db/dyld/dyld* 2>&1
  rm -f  "${2}"/var/pcast/server/krb_cc 2>&1
  rm -f  "${2}"/var/vm/sleepimage 2>&1
  rm -f  "${2}"/var/log/ds_finalize.log 2>&1
  
  if [ -e "${2}"/Library/Filesystems/Xsan/config/uuid ]
  then
    uuidgen > "${2}"/Library/Filesystems/Xsan/config/uuid
    chmod 644 "${2}"/Library/Filesystems/Xsan/config/uuid
    chown root:wheel "${2}"/Library/Filesystems/Xsan/config/uuid
  fi
  if [ -e "${2}"/Library/Preferences/Xsan/uuid ]
  then
    HOSTUUID=`ioreg -rd1 -c IOPlatformExpertDevice | awk -F= '/(UUID)/ { gsub("[ \"]", ""); print $2 }'`
    if [ -n "${HOSTUUID}" ]
    then
      echo "${HOSTUUID}" > "${2}"/Library/Preferences/Xsan/uuid
      chmod 600 "${2}"/Library/Preferences/Xsan/uuid
      chown root:wheel "${2}"/Library/Preferences/Xsan/uuid
    else
      rm "${2}"/Library/Preferences/Xsan/uuid 2>&1
    fi
  fi

  if [ -e "${2}"/System/Library/CoreServices/SystemVersion.plist ] && [ ! -e "${2}"/System/Library/CoreServices/ServerVersion.plist ] && [ -e "${2}"/usr/libexec/configureLocalKDC ]
  then
    rm -rf "${2}/Library/Preferences/OpenDirectory/Configurations/Active Directory" 2>&1
    rm -rf "${2}/Library/Preferences/OpenDirectory/DynamicData/Active Directory" 2>&1
    rm -rf "${2}"/Library/Preferences/DirectoryService/ActiveDirectory.plist 2>&1
    rm -f  "${2}"/var/db/dslocal/nodes/Default/config/KerberosKDC.plist 2>&1
    "${TOOLS_FOLDER}"/deleteKeychainCert "${2}"/Library/Keychains/System.keychain com.apple.kerberos.kdc
    "${TOOLS_FOLDER}"/deleteKeychainCert "${2}"/Library/Keychains/System.keychain com.apple.systemdefault
	rm -f  "${2}"/etc/krb5.keytab 2>&1
	rm -rf "${2}"/var/db/krb5kdc 2>&1
	
    VOLUME_NAME=`basename "${2}"`
    "${TOOLS_FOLDER}"/Common/ds_finalize_install.sh "${VOLUME_NAME}"
  fi
fi

echo "Exiting ${SCRIPT_NAME} v${VERSION}"

exit 0