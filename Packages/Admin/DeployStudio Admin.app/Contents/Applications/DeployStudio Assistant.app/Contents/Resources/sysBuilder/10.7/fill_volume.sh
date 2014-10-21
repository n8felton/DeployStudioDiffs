FILL_VOLUME_VERSION=7.55

if [ -z "${TMP_MOUNT_PATH}" ] || [ "${TMP_MOUNT_PATH}" = "/" ]
then
  echo "Invalid volume target \"${TMP_MOUNT_PATH}\"."
  echo "Aborting ${SCRIPT_NAME} v${VERSION} ("`date`")"
  echo "RuntimeAbortScript"
  exit 1
fi

# build BaseSystem bom
lsbom -s "${BASE_SYSTEM_ROOT_PATH}"/var/db/receipts/com.apple.pkg.BaseSystemBinaries.bom   > /tmp/dss_bs.txt
lsbom -s "${BASE_SYSTEM_ROOT_PATH}"/var/db/receipts/com.apple.pkg.BaseSystemResources.bom >> /tmp/dss_bs.txt
sort -u /tmp/dss_bs.txt > /tmp/dss_bs_sorted.txt
mkbom -s -i /tmp/dss_bs_sorted.txt /tmp/dss_bs.bom
  
# start adding content to the volume
ditto -bom /tmp/dss_bs.bom "${BASE_SYSTEM_ROOT_PATH}"/ "${TMP_MOUNT_PATH}" 2>&1
  
# temp files cleanup
rm /tmp/dss_bs.txt /tmp/dss_bs_sorted.txt /tmp/dss_bs.bom

# add extra content
# ETC_CONF="pam.d smb.conf smb.conf.template"
# for A_ETC_CONF in ${ETC_CONF}
# do
#   add_file_at_path "${A_ETC_CONF}" /etc
# done
# ditto /var/db/smb.conf "${TMP_MOUNT_PATH}/var/db/smb.conf" 2>&1

USR_LIB="pam python2.5 python2.6 python2.7 zsh"
add_files_at_path "${USR_LIB}" /usr/lib

ROOT_BIN="csh ksh tcsh zsh"
add_files_at_path "${ROOT_BIN}" /bin

USR_BIN="afconvert afinfo afplay atos auval auvaltool basename cd chgrp curl diff dirname dscl du egrep \
         erb expect false fgrep fs_usage grep gunzip gzip irb lsbom mkbom open printf rails rake rdoc ri rsync \
         logger say smbutil srm sw_vers syslog testrb xattr xattr-2.5 xattr-2.6 xattr-2.7 xxd bc \
		 certtool kdestroy keytool kgetcred kill.d killall kinit klist kpasswd krb5-config kswitch python top"
add_files_at_path "${USR_BIN}" /usr/bin

USR_SBIN="graphicssession gssd iostat ntpdate smbd spctl systemkeychain vsdbutil \
          kadmin kadmin.local kdcsetup krbservicesetup systemkeychain"
add_files_at_path "${USR_SBIN}" /usr/sbin

add_file_at_path RemoteManagement /System/Library/CoreServices/

USR_SHARE="sandbox"
add_files_at_path "${USR_SHARE}" /usr/share

USR_LIBEXEC="AppSandbox launchdadd nlcd samba security-checksystem \
             checkLocalKDC configureLocalKDC migrateLocalKDC smb-sync-preferences"
add_files_at_path "${USR_LIBEXEC}" /usr/libexec

if [ -e "/tmp/recovery_tools/Startup Disk.app" ]
then
  ditto --rsrc "/tmp/recovery_tools/Startup Disk.app" "${TMP_MOUNT_PATH}/Applications/Utilities/Startup Disk.app"
else
  ditto --rsrc "${SYSBUILDER_FOLDER}/common/Startup Disk.app" "${TMP_MOUNT_PATH}/Applications/Utilities/Startup Disk.app"
fi

if [ -e "/tmp/recovery_tools/Firmware Password Utility.app" ]
then
  ditto --rsrc "/tmp/recovery_tools/Firmware Password Utility.app" "${TMP_MOUNT_PATH}/Applications/Utilities/Firmware Password Utility.app"
fi

if [ -e "/tmp/recovery_tools/Reset Password.app" ]
then
  ditto --rsrc "/tmp/recovery_tools/Reset Password.app" "${TMP_MOUNT_PATH}/Applications/Utilities/Reset Password.app"
fi

ditto --rsrc "${SYSBUILDER_FOLDER}"/common/DefaultDesktopViewer.app "${TMP_MOUNT_PATH}"/Applications/DefaultDesktopViewer.app

LIB_MISC="ColorSync Perl"
add_files_at_path "${LIB_MISC}" /Library

SYS_LIB_MISC="DirectoryServices Displays Filesystems Fonts KerberosPlugins OpenDirectory Perl Sandbox Sounds SystemProfiler Tcl"
add_files_at_path "${SYS_LIB_MISC}" /System/Library

SYS_LIB_CORE="PlatformSupport.plist RemoteManagement SystemUIServer.app ZoomWindow.app"
add_files_at_path "${SYS_LIB_CORE}" /System/Library/CoreServices

SYS_LIB_FRK="ApplicationServices"
add_files_at_path "${SYS_LIB_FRK}" /System/Library/Frameworks .framework

if [ -e "${TMP_MOUNT_PATH}"/System/Library/CoreServices/PlatformSupport.plist ]
then
  defaults write "${TMP_MOUNT_PATH}"/System/Library/CoreServices/PlatformSupport \
      SupportedModelProperties \
      -array-add \
      "MacBookAir5,1" "MacBookAir5,2" \
      "MacBookPro9,1" "MacBookPro9,2" \
      "MacBookPro10,1" "MacBookPro10,2" \
      "Macmini6,1" "Macmini6,2"
  plutil -convert xml1 "${TMP_MOUNT_PATH}"/System/Library/CoreServices/PlatformSupport.plist
  chmod 644 "${TMP_MOUNT_PATH}"/System/Library/CoreServices/PlatformSupport.plist
  chown root:wheel "${TMP_MOUNT_PATH}"/System/Library/CoreServices/PlatformSupport.plist
fi

if [ -e "${TMP_MOUNT_PATH}/System/Library/CoreServices/Menu Extras" ]
then
  rm -rf "${TMP_MOUNT_PATH}/System/Library/CoreServices/Menu Extras"/*
else
  mkdir -p "${TMP_MOUNT_PATH}/System/Library/CoreServices/Menu Extras"
fi
MENU_EXTRAS="TextInput.menu Battery.menu Clock.menu"
add_files_at_path "${MENU_EXTRAS}" "/System/Library/CoreServices/Menu Extras"
cp "${SYSBUILDER_FOLDER}"/common/com.apple.systemuiserver.plist "${TMP_MOUNT_PATH}"/Library/Preferences/
chmod 644        "${TMP_MOUNT_PATH}"/Library/Preferences/com.apple.systemuiserver.plist
chown root:wheel "${TMP_MOUNT_PATH}"/Library/Preferences/com.apple.systemuiserver.plist

OLD_PATH=`pwd`
cd "${BASE_SYSTEM_ROOT_PATH}"/System/Library/Extensions
GRAPHICS_EXT=`ls -d AMD* AppleIntel* ATI* GeForce* NVDA*`
cd "${OLD_PATH}"
add_files_at_path "${GRAPHICS_EXT}" /System/Library/Extensions

SYS_LIB_EXT="IOPlatformPluginFamily IOSCSIArchitectureModelFamily"
add_files_at_path "${SYS_LIB_EXT}" /System/Library/Extensions .kext

if [ -n "${ENABLE_PYTHON}" ]
then
  add_file_at_path Python /Library
fi
	
if [ -n "${ENABLE_RUBY}" ]
then
  add_file_at_path Ruby /Library
  add_file_at_path Ruby.framework /System/Library/Frameworks
  add_file_at_path RubyCocoa.framework /System/Library/Frameworks
  add_file_at_path ruby /usr/lib
  add_file_at_path ruby /usr/bin
fi

# Display mirroring support
ditto --rsrc  "${SYSBUILDER_FOLDER}"/common/enableDisplayMirroring "${TMP_MOUNT_PATH}"/usr/bin/enableDisplayMirroring 2>&1
chmod 755 "${TMP_MOUNT_PATH}"/usr/bin/enableDisplayMirroring 2>&1
chown root:wheel "${TMP_MOUNT_PATH}"/usr/bin/enableDisplayMirroring 2>&1

rm "${TMP_MOUNT_PATH}"/mach
ln -s /mach_kernel "${TMP_MOUNT_PATH}"/mach

cp "${SYSBUILDER_FOLDER}/common/com.deploystudio.server.plist" "${TMP_MOUNT_PATH}/Library/Preferences/com.deploystudio.server.plist"
if [ -n "${SERVER_URL}" ]
then
  defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server server -dict-add url "${SERVER_URL}"
  if [ -n "${SERVER_URL2}" ] && [ "${SERVER_URL2}" != "${SERVER_URL}" ]
  then
    defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server server -dict-add url2 "${SERVER_URL2}"
  fi
fi
if [ -n "${SERVER_LOGIN}" ]
then
  defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server server -dict-add login "${SERVER_LOGIN}"
  if [ -n "${SERVER_PASSWORD}" ]
  then
    defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server server -dict-add password "${SERVER_PASSWORD}"
  fi
fi
if [ -n "${SERVER_DISPLAY_LOGS}" ]
then
  defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server runtime -dict-add displaylogs "YES"
fi
if [ -n "${DISABLE_VERSIONS_MISMATCH_ALERTS}" ]
then
  defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server runtime -dict-add disableVersionsMismatchAlerts "YES"
fi
if [ -n "${TIMEOUT}" ]
then
  defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server runtime -dict-add quitAfterCompletion "YES"
  defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server runtime -dict-add timeoutInSeconds "${TIMEOUT}"
fi
if [ -n "${CUSTOM_RUNTIME_TITLE}" ]
then
  defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server runtime -dict-add customtitle "${CUSTOM_RUNTIME_TITLE}"
fi
chown root:admin "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server.plist 2>&1

if [ ! -e "${TMP_MOUNT_PATH}/System/Installation" ]
then
  mkdir "${TMP_MOUNT_PATH}/System/Installation" 2>&1
fi

if [ -e "${TMP_MOUNT_PATH}/Library/PrivilegedHelperTools" ]
then
  rm -rf "${TMP_MOUNT_PATH}/Library/PrivilegedHelperTools" 2>&1
fi
ln -s /tmp "${TMP_MOUNT_PATH}"/Library/PrivilegedHelperTools 2>&1

# if [ ! -e "${TMP_MOUNT_PATH}/var/db/launchd.db" ]
# then
#   mkdir "${TMP_MOUNT_PATH}/var/db/launchd.db"
# else
#   rm -rf "${TMP_MOUNT_PATH}/var/db/launchd.db"/*
# fi
# mkdir "${TMP_MOUNT_PATH}/var/db/launchd.db/com.apple.launchd"
# chown -R root:wheel "${TMP_MOUNT_PATH}/var/db/launchd.db" 2>&1
# chmod -R 755 "${TMP_MOUNT_PATH}/var/db/launchd.db" 2>&1
#
# if [ -e "${TMP_MOUNT_PATH}/var/db/mds" ]
# then
#   rm -rf "${TMP_MOUNT_PATH}/var/db/mds"
# fi
if [ -e "/Library/Application Support/DeployStudio" ]
then
  ditto --rsrc "/Library/Application Support/DeployStudio" "${TMP_MOUNT_PATH}/Library/Application Support/DeployStudio" 2>&1
  chown -R root:admin "${TMP_MOUNT_PATH}/Library/Application Support/DeployStudio" 2>&1
fi

if [ -e "${TMP_MOUNT_PATH}/Library/Preferences/SystemConfiguration" ]
then
  rm -rf "${TMP_MOUNT_PATH}/Library/Preferences/SystemConfiguration" 2>&1
fi
ditto --rsrc "${SYSBUILDER_FOLDER}/${SYS_VERS}/SystemConfiguration" "${TMP_MOUNT_PATH}/Library/Preferences/SystemConfiguration" 2>&1

if [ -e "${TMP_MOUNT_PATH}/System/Library/LaunchDaemons" ]
then
  rm -rf "${TMP_MOUNT_PATH}/System/Library/LaunchDaemons" 2>&1
fi
ditto --rsrc "${SYSBUILDER_FOLDER}/${SYS_VERS}/LaunchDaemons" "${TMP_MOUNT_PATH}/System/Library/LaunchDaemons" 2>&1
chown -R root:wheel "${TMP_MOUNT_PATH}/System/Library/LaunchDaemons" 2>&1
chmod 755 "${TMP_MOUNT_PATH}"/System/Library/LaunchDaemons 2>&1
chmod 644 "${TMP_MOUNT_PATH}"/System/Library/LaunchDaemons/* 2>&1

if [ -e "${TMP_MOUNT_PATH}/System/Library/LaunchAgents" ]
then
  rm -rf "${TMP_MOUNT_PATH}/System/Library/LaunchAgents" 2>&1
fi
ditto --rsrc "${SYSBUILDER_FOLDER}/${SYS_VERS}/LaunchAgents" "${TMP_MOUNT_PATH}/System/Library/LaunchAgents" 2>&1
chown -R root:wheel "${TMP_MOUNT_PATH}"/System/Library/LaunchAgents 2>&1
chmod 755 "${TMP_MOUNT_PATH}"/System/Library/LaunchAgents 2>&1
chmod 644 "${TMP_MOUNT_PATH}"/System/Library/LaunchAgents/* 2>&1

rm "${TMP_MOUNT_PATH}"/tmp

ln -s var/tmp "${TMP_MOUNT_PATH}"/tmp

ditto /var/run/resolv.conf "${TMP_MOUNT_PATH}/var/run/resolv.conf" 2>&1
ln -s /var/run/resolv.conf "${TMP_MOUNT_PATH}/etc/resolv.conf" 2>&1

cp -R "${SYSBUILDER_FOLDER}/${SYS_VERS}"/etc/* "${TMP_MOUNT_PATH}/etc/" 2>&1
sed s/__DISPLAY_SLEEP__/${DISPLAY_SLEEP}/g "${SYSBUILDER_FOLDER}/${SYS_VERS}"/etc/rc.install > "${TMP_MOUNT_PATH}"/etc/rc.install 2>&1
chmod 555 "${TMP_MOUNT_PATH}"/etc/rc.install 2>&1
chmod 644 "${TMP_MOUNT_PATH}"/etc/hostconfig 2>&1
chmod 644 "${TMP_MOUNT_PATH}"/etc/rc.common 2>&1
chmod 755 "${TMP_MOUNT_PATH}"/etc/rc.cdrom 2>&1

rm -rf "${TMP_MOUNT_PATH}/var/log/"* 2>&1

if [ -e "${TMP_MOUNT_PATH}/Library/Preferences/SystemConfiguration/preferences.plist" ]
then
  rm "${TMP_MOUNT_PATH}/Library/Preferences/SystemConfiguration/preferences.plist" 2>&1
fi

if [ -n "${ARD_PASSWORD}" ]
then
  ditto --rsrc "${SYSBUILDER_FOLDER}"/${SYS_VERS}/com.apple.RemoteManagement.plist "${TMP_MOUNT_PATH}"/Library/Preferences/com.apple.RemoteManagement.plist 2>&1
  echo "${ARD_PASSWORD}" | perl -wne 'BEGIN { @k = unpack "C*", pack "H*", "1734516E8BA8C5E2FF1C39567390ADCA"}; chomp; s/^(.{8}).*/$1/; @p = unpack "C*", $_; foreach (@k) { printf "%02X", $_ ^ (shift @p || 0) }; print "\n"' > "${TMP_MOUNT_PATH}"/Library/Preferences/com.apple.VNCSettings.txt
  chown root:wheel "${TMP_MOUNT_PATH}"/Library/Preferences/com.apple.VNCSettings.txt 2>&1
  chmod 400 "${TMP_MOUNT_PATH}"/Library/Preferences/com.apple.VNCSettings.txt 2>&1

  if [ -n "${ARD_LOGIN}" ]
  then
    ARD_USER_SHORTNAME="${ARD_LOGIN}"
  else
    ARD_USER_SHORTNAME="arduser"
  fi

  ditto "${SYSBUILDER_FOLDER}/${SYS_VERS}/arduser.plist" "${TMP_MOUNT_PATH}/var/db/dslocal/nodes/Default/users/${ARD_USER_SHORTNAME}.plist" 2>&1
  "${SYSBUILDER_FOLDER}"/common/setShadowHashData "${TMP_MOUNT_PATH}/var/db/dslocal/nodes/Default/users/${ARD_USER_SHORTNAME}.plist" "${ARD_PASSWORD}"
  if [ "${ARD_LOGIN}" != "arduser" ]
  then
    defaults write "${TMP_MOUNT_PATH}/var/db/dslocal/nodes/Default/users/${ARD_USER_SHORTNAME}" realname -array "${ARD_USER_SHORTNAME}"
    defaults write "${TMP_MOUNT_PATH}/var/db/dslocal/nodes/Default/users/${ARD_USER_SHORTNAME}" name -array "${ARD_USER_SHORTNAME}"
  fi
  chmod 600 "${TMP_MOUNT_PATH}/var/db/dslocal/nodes/Default/users/${ARD_USER_SHORTNAME}.plist" 2>&1
fi

if [ -n "${NTP_SERVER}" ]
then
  echo "server ${NTP_SERVER}" > "${TMP_MOUNT_PATH}"/etc/ntp.conf
  NTP_SERVER_IPS=`host "${NTP_SERVER}"`
  if [ ${?} -eq 0 ]
  then
    NTP_SERVERS=`echo "${NTP_SERVER_IPS}" | awk '{ print "server "$NF }'`
    echo "${NTP_SERVERS}" >> "${TMP_MOUNT_PATH}"/etc/ntp.conf
  fi
  chmod 644 "${TMP_MOUNT_PATH}"/etc/ntp.conf 2>&1
  chown root:wheel "${TMP_MOUNT_PATH}"/etc/ntp.conf 2>&1
fi

mkdir "${TMP_MOUNT_PATH}"/Library/Caches 2>&1
chmod 1777 "${TMP_MOUNT_PATH}"/Library/Caches 2>&1
chown -R root:admin "${TMP_MOUNT_PATH}"/Library/Caches 2>&1

# improve tcp performance (risky)
if [ -n "${ENABLE_CUSTOM_TCP_STACK_SETTINGS}" ]
then
  enable_custom_tcp_stack_settings
fi

chmod -R 644 "${TMP_MOUNT_PATH}"/Library/Preferences/* 2>&1
chmod 755 "${TMP_MOUNT_PATH}"/Library/Preferences/DirectoryService 2>&1
chmod 755 "${TMP_MOUNT_PATH}"/Library/Preferences/SystemConfiguration 2>&1
chown -R root:wheel "${TMP_MOUNT_PATH}"/Library/Preferences/* 2>&1

touch "${TMP_MOUNT_PATH}"/System/Library/CoreServices/ServerVersion.plist 2>&1
chmod 444 "${TMP_MOUNT_PATH}"/System/Library/CoreServices/ServerVersion.plist 2>&1
chown root:wheel "${TMP_MOUNT_PATH}"/System/Library/CoreServices/ServerVersion.plist 2>&1

if [ -n "${CUSTOM_RUNTIME_BACKGROUND}" ] && [ -f "${CUSTOM_RUNTIME_BACKGROUND}" ]
then
  ditto --rsrc "${CUSTOM_RUNTIME_BACKGROUND}" "${TMP_MOUNT_PATH}"/System/Library/CoreServices/DefaultDesktop.jpg
else
  ditto --rsrc "${SYSBUILDER_FOLDER}"/common/DefaultDesktop.jpg "${TMP_MOUNT_PATH}"/System/Library/CoreServices/DefaultDesktop.jpg
fi

if [ -e "/Applications/Utilities/DeployStudio Admin.app" ]
then
  ditto --rsrc "/Applications/Utilities/DeployStudio Admin.app" "${TMP_MOUNT_PATH}/Applications/Utilities/DeployStudio Admin.app" 2>&1
elif [ -e "${SYSBUILDER_FOLDER}/../../../../Applications/Utilities/DeployStudio Admin.app" ]
then
  ditto --rsrc "${SYSBUILDER_FOLDER}/../../../../Applications/Utilities/DeployStudio Admin.app" "${TMP_MOUNT_PATH}/Applications/Utilities/DeployStudio Admin.app" 2>&1
fi
chown -R root:admin "${TMP_MOUNT_PATH}/Applications/Utilities/DeployStudio Admin.app" 2>&1

# find and add missing libs
if [ -z "${BASE_SYSTEM_ROOT_PATH}" ]
then
  "${SYSBUILDER_FOLDER}"/netboot_helpers/ds_fix_shared_libs.sh "${TMP_MOUNT_PATH}"
else
  "${SYSBUILDER_FOLDER}"/netboot_helpers/ds_fix_shared_libs.sh "${TMP_MOUNT_PATH}" "${BASE_SYSTEM_ROOT_PATH}"
fi

# disable spotlight indexing again (just in case)
mdutil -i off "${TMP_MOUNT_PATH}"
mdutil -E "${TMP_MOUNT_PATH}"
defaults write "${TMP_MOUNT_PATH}"/.Spotlight-V100/_IndexPolicy Policy -int 3

rm -rf "${TMP_MOUNT_PATH}"/System/Library/Caches/com.apple.bootstamps
rm -rf "${TMP_MOUNT_PATH}"/System/Library/Caches/*
rm -r  "${TMP_MOUNT_PATH}"/System/Library/Extensions.mkext
rm -r  "${TMP_MOUNT_PATH}"/System/Library/LaunchDaemons/com.apple.SystemUIServer.plist
rm -r  "${TMP_MOUNT_PATH}"/usr/standalone/bootcaches.plist
rm -f  "${TMP_MOUNT_PATH}"/var/db/BootCache*

if [ -e "${TMP_MOUNT_PATH}"/Volumes ]
then
  rm -rf "${TMP_MOUNT_PATH}"/Volumes/* 2>&1
fi