FILL_VOLUME_VERSION=10.62

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
ETC_CONF="ntp.conf pam.d"
add_files_at_path "${ETC_CONF}" /etc

ROOT_BIN="csh ksh tcsh zsh"
add_files_at_path "${ROOT_BIN}" /bin

USR_BIN="afconvert afinfo afplay atos auval auvaltool basename cd chgrp curl diff dirname dscl du egrep \
         erb expect false fgrep fs_usage grep gunzip gzip irb lsbom mkbom open printf rails rake rdoc ri rsync \
         say smbutil srm sw_vers syslog testrb xattr xattr-2.5 xattr-2.6 xattr-2.7 xxd bc \
         certtool kdestroy keytool kgetcred killall kinit klist kpasswd krb5-config kswitch perl5.16 perl5.18 python top"
add_files_at_path "${USR_BIN}" /usr/bin

USR_SBIN="cfprefsd distnoted gssd iostat kadmin kadmin.local kdcsetup krbservicesetup mDNSResponder mDNSResponderHelper ntpdate \
          smbd spctl systemkeychain vsdbutil"
add_files_at_path "${USR_SBIN}" /usr/sbin

USR_LIB="pam python2.5 python2.6 python2.7 zsh"
add_files_at_path "${USR_LIB}" /usr/lib

USR_SHARE="sandbox terminfo zoneinfo"
add_files_at_path "${USR_SHARE}" /usr/share

USR_LIBEXEC="checkLocalKDC configureLocalKDC dirhelper launchdadd migrateLocalKDC security-checksystem smb-sync-preferences xpcd \
             displaypolicyd nsurlsessiond nsurlstoraged"
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

SYS_LIB_MISC="DirectoryServices Displays Fonts KerberosPlugins OpenDirectory Perl Sandbox Sounds SystemProfiler Tcl"
add_files_at_path "${SYS_LIB_MISC}" /System/Library

SYS_LIB_CORE="CoreTypes.bundle ManagedClient.app PlatformSupport.plist RemoteManagement SecurityAgentPlugins \
              SystemUIServer.app SystemAppearance.bundle ZoomWindow.app boot.efi"
add_files_at_path "${SYS_LIB_CORE}" /System/Library/CoreServices

# 10.10 DP3 fix
cp -f "${BASE_SYSTEM_ROOT_PATH}"/Library/Fonts/AppleSDGothicNeo* "${TMP_MOUNT_PATH}"/System/Library/Fonts/
#

# 10.9.2 fixes
add_file_at_path AppleGraphicsDevicePolicy.kext /System/Library/Extensions/AppleGraphicsControl.kext/Contents/PlugIns/
add_file_at_path AppleMGPUPowerControl.kext /System/Library/Extensions/AppleGraphicsControl.kext/Contents/PlugIns/
add_file_at_path Resources /System/Library/Extensions/IOPlatformPluginFamily.kext/Contents/PlugIns/X86PlatformPlugin.kext/Contents/
add_file_at_path PlugIns /System/Library/Frameworks/Security.framework/Versions/A/
#

cp "${BASE_SYSTEM_ROOT_PATH}"/var/db/auth.db* "${TMP_MOUNT_PATH}"/var/db/

if [ -e "${TMP_MOUNT_PATH}"/System/Library/CoreServices/PlatformSupport.plist ] 
then
  defaults write "${TMP_MOUNT_PATH}"/System/Library/CoreServices/PlatformSupport \
    SupportedModelProperties \
    -array-add \
    "iMac14,1" "iMac14,2" "MacBookPro11,1" "MacBookPro11,2" "MacBookPro11,3"
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

SYS_LIB_EXT="AppleFIVRDriver AppleHDA AppleHPM AppleStorageDrivers AppleTopCase IOAHCIFamily IONVMeFamily IOStorageFamily"
add_files_at_path "${SYS_LIB_EXT}" /System/Library/Extensions .kext

SYS_LIB_EXT_PLUG="NVMeSMARTLib"
add_files_at_path "${SYS_LIB_EXT_PLUG}" /System/Library/Extensions .plugin

SYS_LIB_FRK="ApplicationServices vecLib"
add_files_at_path "${SYS_LIB_FRK}" /System/Library/Frameworks .framework

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

# Temporary OpenGL fix
if [ -e "/tmp/recovery_tools/OpenCL.framework" ]
then
  ditto --rsrc "/tmp/recovery_tools/OpenCL.framework" "${TMP_MOUNT_PATH}"/System/Library/Frameworks/OpenCL.framework
fi
add_file_at_path libCLVMIGILPlugin.dylib /System/Library/Frameworks/OpenCL.framework/Libraries
add_file_at_path IGIL.dylib /System/Library/Frameworks/OpenCL.framework/Libraries
if [ -e "/tmp/recovery_tools/OpenGL.framework" ]
then
  ditto --rsrc "/tmp/recovery_tools/OpenGL.framework" "${TMP_MOUNT_PATH}"/System/Library/Frameworks/OpenGL.framework
fi

# Display mirroring support
ditto --rsrc  "${SYSBUILDER_FOLDER}"/common/enableDisplayMirroring "${TMP_MOUNT_PATH}"/usr/bin/enableDisplayMirroring 2>&1
chmod 755 "${TMP_MOUNT_PATH}"/usr/bin/enableDisplayMirroring 2>&1
chown root:wheel "${TMP_MOUNT_PATH}"/usr/bin/enableDisplayMirroring 2>&1

ditto --rsrc "${BASE_SYSTEM_ROOT_PATH}"/System/Library/Kernels "${TMP_MOUNT_PATH}"/System/Library/Kernels

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

if [ -e "/Library/Application Support/DeployStudio" ]
then
  ditto --rsrc "/Library/Application Support/DeployStudio" "${TMP_MOUNT_PATH}/Library/Application Support/DeployStudio" 2>&1
  chown -R root:admin "${TMP_MOUNT_PATH}/Library/Application Support/DeployStudio" 2>&1
fi

if [ -e "${TMP_MOUNT_PATH}/Library/Preferences/SystemConfiguration" ]
then
  rm -rf "${TMP_MOUNT_PATH}/Library/Preferences/SystemConfiguration" 2>&1
fi
ditto --rsrc "${SYS_VERS_FOLDER}/SystemConfiguration" "${TMP_MOUNT_PATH}/Library/Preferences/SystemConfiguration" 2>&1

cp -R "${SYS_VERS_FOLDER}"/LaunchDaemons/* "${TMP_MOUNT_PATH}"/System/Library/LaunchDaemons/ 2>&1
chmod 644 "${TMP_MOUNT_PATH}"/System/Library/LaunchDaemons/* 2>&1

cp -R "${SYS_VERS_FOLDER}"/LaunchAgents/* "${TMP_MOUNT_PATH}"/System/Library/LaunchAgents/ 2>&1
chmod 644 "${TMP_MOUNT_PATH}"/System/Library/LaunchAgents/* 2>&1

if [ ! -e "${TMP_MOUNT_PATH}"/usr/sbin/mDNSResponder ]
then
  rm "${TMP_MOUNT_PATH}"/System/Library/LaunchDaemons/com.apple.mDNSResponder.plist
fi

if [ ! -e "${TMP_MOUNT_PATH}"/usr/sbin/mDNSResponderHelper ]
then
  rm "${TMP_MOUNT_PATH}"/System/Library/LaunchDaemons/com.apple.mDNSResponderHelper.plist
fi

rm "${TMP_MOUNT_PATH}"/tmp

ln -s var/tmp "${TMP_MOUNT_PATH}"/tmp

ditto /var/run/resolv.conf "${TMP_MOUNT_PATH}/var/run/resolv.conf" 2>&1
ln -s /var/run/resolv.conf "${TMP_MOUNT_PATH}/etc/resolv.conf" 2>&1

cp -R "${SYS_VERS_FOLDER}"/etc/* "${TMP_MOUNT_PATH}/etc/" 2>&1
sed s/__DISPLAY_SLEEP__/${DISPLAY_SLEEP}/g "${SYS_VERS_FOLDER}"/etc/rc.install > "${TMP_MOUNT_PATH}"/etc/rc.install 2>&1
chmod 555 "${TMP_MOUNT_PATH}"/etc/rc.install 2>&1
chmod 644 "${TMP_MOUNT_PATH}"/etc/hostconfig 2>&1
chmod 644 "${TMP_MOUNT_PATH}"/etc/rc.common 2>&1
chmod 755 "${TMP_MOUNT_PATH}"/etc/rc.cdrom 2>&1
chmod 644 "${TMP_MOUNT_PATH}"/etc/nsmb.conf 2>&1

rm -rf "${TMP_MOUNT_PATH}/var/log/"* 2>&1

if [ -e "${TMP_MOUNT_PATH}/Library/Preferences/SystemConfiguration/NetworkInterfaces.plist" ]
then
  rm "${TMP_MOUNT_PATH}/Library/Preferences/SystemConfiguration/NetworkInterfaces.plist" 2>&1
fi

if [ -e "${TMP_MOUNT_PATH}/Library/Preferences/SystemConfiguration/preferences.plist" ]
then
  rm "${TMP_MOUNT_PATH}/Library/Preferences/SystemConfiguration/preferences.plist" 2>&1
fi

if [ -n "${ARD_PASSWORD}" ]
then
  ditto --rsrc "${SYS_VERS_FOLDER}"/com.apple.RemoteDesktop.plist "${TMP_MOUNT_PATH}"/Library/Preferences/com.apple.RemoteDesktop.plist 2>&1
  ditto --rsrc "${SYS_VERS_FOLDER}"/com.apple.RemoteManagement.plist "${TMP_MOUNT_PATH}"/Library/Preferences/com.apple.RemoteManagement.plist 2>&1
  echo "${ARD_PASSWORD}" | perl -wne 'BEGIN { @k = unpack "C*", pack "H*", "1734516E8BA8C5E2FF1C39567390ADCA"}; chomp; s/^(.{8}).*/$1/; @p = unpack "C*", $_; foreach (@k) { printf "%02X", $_ ^ (shift @p || 0) }; print "\n"' > "${TMP_MOUNT_PATH}"/Library/Preferences/com.apple.VNCSettings.txt
  chown root:wheel "${TMP_MOUNT_PATH}"/Library/Preferences/com.apple.VNCSettings.txt 2>&1
  chmod 400 "${TMP_MOUNT_PATH}"/Library/Preferences/com.apple.VNCSettings.txt 2>&1

  echo enabled > "${TMP_MOUNT_PATH}"/etc/RemoteManagement.launchd
  chown root:wheel "${TMP_MOUNT_PATH}"/etc/RemoteManagement.launchd 2>&1
  chmod 644 "${TMP_MOUNT_PATH}"/etc/RemoteManagement.launchd 2>&1

  echo enabled > "${TMP_MOUNT_PATH}"/etc/com.apple.screensharing.agent.launchd
  chown root:wheel "${TMP_MOUNT_PATH}"/etc/com.apple.screensharing.agent.launchd 2>&1
  chmod 644 "${TMP_MOUNT_PATH}"/etc/com.apple.screensharing.agent.launchd 2>&1

  if [ -n "${ARD_LOGIN}" ]
  then
    ARD_USER_SHORTNAME="${ARD_LOGIN}"
  else
    ARD_USER_SHORTNAME="arduser"
  fi

  ditto "${SYS_VERS_FOLDER}/arduser.plist" "${TMP_MOUNT_PATH}/var/db/dslocal/nodes/Default/users/${ARD_USER_SHORTNAME}.plist" 2>&1
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
mkdir "${TMP_MOUNT_PATH}"/Library/Preferences/DirectoryService 2>&1
chmod 755 "${TMP_MOUNT_PATH}"/Library/Preferences/DirectoryService 2>&1
chmod 755 "${TMP_MOUNT_PATH}"/Library/Preferences/SystemConfiguration 2>&1
chown -R root:wheel "${TMP_MOUNT_PATH}"/Library/Preferences/* 2>&1

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

rm -rf "${TMP_MOUNT_PATH}"/System/Library/Caches/*
rm -r  "${TMP_MOUNT_PATH}"/System/Library/Extensions.mkext
rm -r  "${TMP_MOUNT_PATH}"/System/Library/LaunchDaemons/com.apple.ocspd.plist
rm -r  "${TMP_MOUNT_PATH}"/System/Library/LaunchDaemons/com.apple.tccd.system.plist
rm -rf "${TMP_MOUNT_PATH}"/System/Library/SystemProfiler/SPManagedClientReporter.spreporter
rm -rf "${TMP_MOUNT_PATH}"/System/Library/SystemProfiler/SPConfigurationProfileReporter.spreporter
rm -f  "${TMP_MOUNT_PATH}"/var/db/dslocal/nodes/Default/computers/localhost.plist
rm -f  "${TMP_MOUNT_PATH}"/var/db/BootCache*

# # Temporary OpenGL fix
# rm -f  "${TMP_MOUNT_PATH}"/System/Library/LaunchDaemons/com.apple.cvmsServ.plist

mkdir -p "${TMP_MOUNT_PATH}"/System/Library/Caches/com.apple.CVMS
mkdir -p "${TMP_MOUNT_PATH}"/System/Library/Caches/com.apple.kext.caches/Directories/System/Library/Extensions
mkdir -p "${TMP_MOUNT_PATH}"/System/Library/Caches/com.apple.kext.caches/Startup
chown -R root:wheel "${TMP_MOUNT_PATH}"/System/Library/Caches

if [ -e "${TMP_MOUNT_PATH}"/Volumes ]
then
  rm -rf "${TMP_MOUNT_PATH}"/Volumes/* 2>&1
fi
