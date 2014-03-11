FILL_VOLUME_VERSION=6.53

if [ -z "${TMP_MOUNT_PATH}" ] || [ "${TMP_MOUNT_PATH}" = "/" ]
then
  echo "Invalid volume target \"${TMP_MOUNT_PATH}\"."
  echo "Aborting ${SCRIPT_NAME} v${VERSION} ("`date`")"
  echo "RuntimeAbortScript"
  exit 1
fi

# start adding content to the volume
ditto -bom "${SYSBUILDER_FOLDER}/${SYS_VERS}/${ARCH}.bom" "${BASE_SYSTEM_ROOT_PATH}"/ "${TMP_MOUNT_PATH}" 2>&1

rm -rf "${TMP_MOUNT_PATH}"/System/Library/Extensions/IOSerialFamily.kext/Contents/PlugIns/*

ETC_CONF="pam.d smb.conf smb.conf.template"
add_files_at_path "${ETC_CONF}" /etc

ditto "${BASE_SYSTEM_ROOT_PATH}"/var/db/smb.conf "${TMP_MOUNT_PATH}/var/db/smb.conf" 2>&1
  
USR_LIB="libapr-1.0.3.8.dylib libaprutil-1.0.3.9.dylib libtcl.dylib libtk.dylib libXplugin.1.dylib mecab pam pkgconfig samba sasl2 \
         libwx_macud-2.8.0.dylib libwx_macud_stc-2.8.0.dylib zsh"
add_files_at_path "${USR_LIB}" /usr/lib

ROOT_BIN="csh ksh tcsh zsh"
add_files_at_path "${ROOT_BIN}" /bin

USR_BIN="afconvert afinfo afplay auval auvaltool basename cd chflags chgrp curl cut diff dirname dscl du egrep \
         expect false fgrep fs_usage gunzip gzip less lsbom mkbom more nmblookup ntlm_auth open printf rsync say sort srm \
   		 smbcacls smbclient smbcontrol smbcquotas smbget smbpasswd smbspool smbstatus smbtree smbutil \
	  	 tail tr uuidgen vi vim xxd bsdtar syslog bc python"
add_files_at_path "${USR_BIN}" /usr/bin

USR_SBIN="gssd installer iostat ipconfig nmbd ntpdate smbd systemsetup vsdbutil winbindd"
add_files_at_path "${USR_SBIN}" /usr/sbin

USR_SHARE="sandbox terminfo zoneinfo"
add_files_at_path "${USR_SHARE}" /usr/share

USR_LIBEXEC="samba"
add_files_at_path "${USR_LIBEXEC}" /usr/libexec

add_file_at_path "Disk Utility.app" /Applications/Utilities
add_file_at_path "Network Utility.app" /Applications/Utilities
add_file_at_path "RAID Utility.app" /Applications/Utilities
add_file_at_path "System Profiler.app" /Applications/Utilities
add_file_at_path "Terminal.app" /Applications/Utilities

ditto --rsrc "${SYSBUILDER_FOLDER}/common/Startup Disk.app" "${TMP_MOUNT_PATH}/Applications/Utilities/Startup Disk.app"
ditto --rsrc "${SYSBUILDER_FOLDER}"/common/DefaultDesktopViewer.app "${TMP_MOUNT_PATH}"/Applications/DefaultDesktopViewer.app

LIB_MISC="ColorSync Perl"
add_files_at_path "${LIB_MISC}" /Library

SYS_LIB="DirectoryServices Displays Filesystems KerberosPlugins LoginPlugins Perl Sandbox"
add_files_at_path "${SYS_LIB}" /System/Library

SYS_LIB_COMP="AudioCodecs CoreAudio"
add_files_at_path "${SYS_LIB_COMP}" /System/Library/Components .component

SYS_LIB_CORE="CoreTypes.bundle KernelEventAgent.bundle RemoteManagement SecurityAgentPlugins"
add_files_at_path "${SYS_LIB_CORE}" /System/Library/CoreServices

add_file_at_path "TextInput.menu" "/System/Library/CoreServices/Menu Extras"
add_file_at_path "Setup Assistant.app" /System/Library/CoreServices
add_file_at_path Voices /System/Library/Speech
add_file_at_path Sounds /System/Library

SYS_LIB_EXT="AppleBMC AppleBluetoothMultitouch AppleHIDKeyboard AppleIntelCPUPowerManagementClient AppleMultitouchDriver AppleProfileFamily \
		     AppleUSBEthernetHost AppleIntelHDGraphics AppleIntelHDGraphicsFB AppleIntelSNBGraphicsFB \
             ATI4500Controller ATI4600Controller ATI5000Controller ATI6000Controller ATIRadeonX3000 BJUSBLoad IOPlatformPluginFamily \
			 AppleBacklightExpert IO80211Family AppleHDA System PromiseSTEX \
             AppleThunderboltEDMService AppleThunderboltDPAdapters AppleThunderboltNHI AppleThunderboltPCIAdapters AppleThunderboltUTDM IOThunderboltFamily"
add_files_at_path "${SYS_LIB_EXT}" /System/Library/Extensions .kext

SYS_LIB_EXT_BDL="AppleIntelHDGraphicsGLDriver AppleIntelHDGraphicsVADriver ATIRadeonX3000VADriver ATIRadeonX3000GLDriver GeForceGLDriver"
add_files_at_path "${SYS_LIB_EXT_BDL}" /System/Library/Extensions .bundle

SYS_LIB_EXT_PLUG="AppleIntelHDGraphicsGA ATIRadeonX3000GA"
add_files_at_path "${SYS_LIB_EXT_PLUG}" /System/Library/Extensions .plugin

SYS_LIB_FRK="AppKit ApplicationServices CoreFoundation CoreVideo CoreServices IOBluetooth JavaScriptCore Kernel LDAP OpenCL OpenDirectory \
             OpenGL PreferencePanes QTKit Quartz QuickTime Security ServiceManagement WebKit Carbon \
             AddressBook CoreAudioKit CoreMIDI FWAUserLib ImageCaptureCore Message OpenAL PubSub Python QuickLook Ruby Tcl Tk \
             AGL CalendarStore RubyCocoa ScriptingBridge ServerNotification AppleConnect nt"
add_files_at_path "${SYS_LIB_FRK}" /System/Library/Frameworks .framework

SYS_LIB_PREF_PANES="StartupDisk"
add_files_at_path "${SYS_LIB_PREF_PANES}" /System/Library/PreferencePanes .prefPane

SYS_LIB_PRIV_FRK="AppleVA BezelServices CommerceKit CoreMedia CoreMediaIOServices DSObjCWrappers DisplayServices MonitorPanel HelpData \
                  MachineSettings MediaToolbox MobileDevice PlatformHardwareManagement ScreenSharing Shortcut VideoToolbox \
                  AVFoundationCF AppleGVA CoreKE Install \
                  ByteRangeLocking ClockMenuExtraPreferences CoreAUC CoreChineseEngine CorePDF DataDetectorsCore DeviceLink \
                  DotMacLegacy FWAVC GraphKit Heimdal International MDSChannel MPWXmlCore MeshKit PasswordServer \
                  PrintingPrivate ProxyHelper ServerFoundation ServerKit SetupAssistant SetupAssistantSupport \
                  SoftwareUpdate SpeechObjects SpotlightIndex SyncServicesUI SystemUIPlugin \
                  DAVKit DotMacSyncManager ExchangeWebServices FileSync ISSupport IntlPreferences OpenDirectoryConfig \
                  OpenDirectoryConfigUI iCalendar AOSNotification WhitePages XMPP ApplePushService"
add_files_at_path "${SYS_LIB_PRIV_FRK}" /System/Library/PrivateFrameworks .framework

SYS_LIB_FONTS="Geneva Helvetica Monaco"
add_files_at_path "${SYS_LIB_FONTS}" /System/Library/Fonts .dfont

rm -rf "${TMP_MOUNT_PATH}"/System/Library/SystemProfiler/*.spreporter
SYS_LIB_PROFILERS="SPAirPortReporter SPAudioReporter SPBluetoothReporter SPDiagnosticsReporter SPDisplaysReporter SPEthernetReporter SPFibreChannelReporter SPFireWireReporter SPHardwareRAIDReporter \
                   SPMemoryReporter SPNetworkReporter SPOSReporter SPPCIReporter SPParallelATAReporter SPParallelSCSIReporter SPPlatformReporter SPPowerReporter \
		     	   SPSASReporter SPSerialATAReporter SPUSBReporter SPWWANReporter SPThunderboltReporter"
add_files_at_path "${SYS_LIB_PROFILERS}" /System/Library/SystemProfiler .spreporter

if [ -e "${TMP_MOUNT_PATH}"/System/Library/Tcl ] 
then
  rm -rf "${TMP_MOUNT_PATH}"/System/Library/Tcl
fi
ditto --rsrc "${BASE_SYSTEM_ROOT_PATH}"/System/Library/Tcl "${TMP_MOUNT_PATH}/System/Library/Tcl" 

if [ -n "${ENABLE_PYTHON}" ]
then
  add_file_at_path Python /Library
  cp -p -R "${BASE_SYSTEM_ROOT_PATH}"/usr/lib/python* "${TMP_MOUNT_PATH}"/usr/lib/ 2>&1
fi
  
if [ -n "${ENABLE_RUBY}" ]
then
  add_file_at_path Ruby /Library
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

if [ ! -e "${TMP_MOUNT_PATH}/Library/Logs" ]
then
  mkdir "${TMP_MOUNT_PATH}/Library/Logs" 2>&1
fi

if [ ! -e "${TMP_MOUNT_PATH}/var/db/launchd.db" ]
then
  mkdir "${TMP_MOUNT_PATH}/var/db/launchd.db"
else
  rm -rf "${TMP_MOUNT_PATH}/var/db/launchd.db"/*
fi
mkdir "${TMP_MOUNT_PATH}/var/db/launchd.db/com.apple.launchd"
chown -R root:wheel "${TMP_MOUNT_PATH}/var/db/launchd.db" 2>&1
chmod -R 755 "${TMP_MOUNT_PATH}/var/db/launchd.db" 2>&1

if [ -e "${TMP_MOUNT_PATH}/var/db/mds" ]
then
  rm -rf "${TMP_MOUNT_PATH}/var/db/mds"
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

if [ -e "/Library/Application Support/DeployStudio" ]
then
  ditto --rsrc "/Library/Application Support/DeployStudio" "${TMP_MOUNT_PATH}/Library/Application Support/DeployStudio" 2>&1
  chown -R root:admin "${TMP_MOUNT_PATH}/Library/Application Support/DeployStudio" 2>&1
fi

if [ -e "${TMP_MOUNT_PATH}/Library/Preferences/SystemConfiguration/preferences.plist" ]
then
  rm "${TMP_MOUNT_PATH}/Library/Preferences/SystemConfiguration/preferences.plist" 2>&1
fi
 
if [ -n "${ARD_PASSWORD}" ]
then
  ditto --rsrc "${SYSBUILDER_FOLDER}"/${SYS_VERS}/com.apple.RemoteManagement.plist "${TMP_MOUNT_PATH}"/Library/Preferences/com.apple.RemoteManagement.plist 2>&1

  ditto --rsrc "${SYSBUILDER_FOLDER}/common/OSXvnc-server" "${TMP_MOUNT_PATH}/usr/bin/OSXvnc-server" 2>&1
  chmod 755 "${TMP_MOUNT_PATH}"/usr/bin/OSXvnc-server 2>&1
  chown root:wheel "${TMP_MOUNT_PATH}"/usr/bin/OSXvnc-server 2>&1

  echo enabled > "${TMP_MOUNT_PATH}"/etc/ScreenSharing.launchd
  "${SYSBUILDER_FOLDER}"/common/storepasswd "${ARD_PASSWORD}" "${TMP_MOUNT_PATH}/Library/Preferences/com.osxvnc.txt" 2>&1
  chmod 644 "${TMP_MOUNT_PATH}"/Library/Preferences/com.osxvnc.txt 2>&1
  chown root:wheel "${TMP_MOUNT_PATH}"/Library/Preferences/com.osxvnc.txt 2>&1
  echo "${ARD_PASSWORD}" | perl -wne 'BEGIN { @k = unpack "C*", pack "H*", "1734516E8BA8C5E2FF1C39567390ADCA"}; chomp; s/^(.{8}).*/$1/; @p = unpack "C*", $_; foreach (@k) { printf "%02X", $_ ^ (shift @p || 0) }; print "\n"' > "${TMP_MOUNT_PATH}"/Library/Preferences/com.apple.VNCSettings.txt
  chmod 400 "${TMP_MOUNT_PATH}"/Library/Preferences/com.apple.VNCSettings.txt 2>&1
  chown root:wheel "${TMP_MOUNT_PATH}"/Library/Preferences/com.apple.VNCSettings.txt 2>&1
fi

if [ -n "${NTP_SERVER}" ]
then
  echo "${NTP_SERVER}" > "${TMP_MOUNT_PATH}"/Library/Preferences/ntpserver.txt
  chmod 644 "${TMP_MOUNT_PATH}"/Library/Preferences/ntpserver.txt 2>&1
  chown root:wheel "${TMP_MOUNT_PATH}"/Library/Preferences/ntpserver.txt 2>&1
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

# disable spotlight indexing again (just in case)
mdutil -i off "${TMP_MOUNT_PATH}"
mdutil -E "${TMP_MOUNT_PATH}"
defaults write "${TMP_MOUNT_PATH}"/.Spotlight-V100/_IndexPolicy Policy -int 3

rm -rf "${TMP_MOUNT_PATH}"/System/Library/Caches/com.apple.bootstamps
rm -rf "${TMP_MOUNT_PATH}"/System/Library/Caches/*
rm -r  "${TMP_MOUNT_PATH}"/System/Library/Extensions.mkext
rm -r  "${TMP_MOUNT_PATH}"/usr/standalone/bootcaches.plist
rm -f  "${TMP_MOUNT_PATH}"/var/db/BootCache*

if [ -e "${TMP_MOUNT_PATH}"/Volumes ]
then
  rm -rf "${TMP_MOUNT_PATH}"/Volumes/* 2>&1
fi