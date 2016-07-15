#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
SCRIPT_PATH=`dirname "${0}"`

/bin/echo "${SCRIPT_NAME} - v1.37 ("`date`")"

custom_logger() {
  /bin/echo "${SCRIPT_NAME} - $1"
}

exec_if_exists() {
  if [ -e "${1}" ]
  then
    custom_logger "running ${1}"
    "${1}"
    if [ ${?} -ne 0 ]
    then
      /bin/echo `/bin/date` >> "/etc/deploystudio/bin/.ds_finalize.calls"
      custom_logger "script execution failed, system will automatically reboot."
      custom_logger "end"
      /sbin/reboot -l
      exit 0
    fi
  fi
}

restore_initial_config() {
  # reenable indexing
  /usr/bin/mdutil -i on / >/dev/null 2>&1

  # restoring default login password
  AUTO_LOGIN_USER=`defaults read /etc/deploystudio/etc/autoLoginUser autoLoginUser 2>/dev/null`
  if [ -n "${AUTO_LOGIN_USER}" ]
  then
    if [ -e /etc/deploystudio/etc/kcpassword ]
    then
      /bin/mv /etc/deploystudio/etc/kcpassword /etc/
    fi
    defaults write /Library/Preferences/com.apple.loginwindow autoLoginUser "${AUTO_LOGIN_USER}"
    chmod 644 /Library/Preferences/com.apple.loginwindow.plist
    chown root:wheel /Library/Preferences/com.apple.loginwindow.plist
  fi

  # reenable Apple Setup if needed
  if [ -e /var/db/.ds.delete.AppleSetupDone ] && [ ! -e /var/db/.ds.preserve.AppleSetupDone ]
  then
    /bin/rm /var/db/.AppleSetupDone
    /bin/rm /var/db/.ds.delete.AppleSetupDone
  else
    /bin/rm /var/db/.ds.delete.AppleSetupDone   2>/dev/null
    /bin/rm /var/db/.ds.preserve.AppleSetupDone 2>/dev/null
  fi

  # enable homedirs freeze if needed
  if [ -e /Library/LaunchDaemons/com.deploystudio.freezeHomedirs.plist ]
  then
    /usr/bin/defaults write /Library/LaunchDaemons/com.deploystudio.freezeHomedirs Disabled -bool NO
    /bin/chmod 644 /Library/LaunchDaemons/com.deploystudio.freezeHomedirs.plist
  fi
}

final_cleanup() {
  # update launchd configuration files status
  if [ -e /Library/LaunchDaemons/com.deploystudio.finalizeScript.plist ]
  then
    /usr/bin/defaults write /Library/LaunchDaemons/com.deploystudio.finalizeScript Disabled -bool YES
    /bin/chmod 644 /Library/LaunchDaemons/com.deploystudio.finalizeScript.plist
  else
    /usr/bin/defaults write /Library/LaunchAgents/com.deploystudio.finalizeScript Disabled -bool YES
    /bin/chmod 644 /Library/LaunchAgents/com.deploystudio.finalizeScript.plist
    /usr/bin/defaults write /Library/LaunchAgents/com.deploystudio.FinalizeApp Disabled -bool YES
    /bin/chmod 644 /Library/LaunchAgents/com.deploystudio.FinalizeApp.plist
  fi

  /usr/bin/defaults write /Library/LaunchDaemons/com.deploystudio.finalizeCleanup Disabled -bool NO
  /bin/chmod 644 /Library/LaunchDaemons/com.deploystudio.finalizeCleanup.plist

  custom_logger "${1}"
  custom_logger "end"
}

#
# Disable this script if it caused more than 3 reboots
#
if [ -e "/etc/deploystudio/bin/.ds_finalize.calls" ] && [ `/usr/bin/wc -l "/etc/deploystudio/bin/.ds_finalize.calls" | /usr/bin/awk '{ print $1 }'` -gt 3 ]
then
  custom_logger "this computer has already rebooted 3 times because of ds_finalize.sh script."
  custom_logger "DeployStudio post-restoration script will be disabled and system will automatically reboot."
  
  # disable launchd configuration files
  if [ -e /Library/LaunchDaemons/com.deploystudio.finalizeScript.plist ]
  then
    /usr/bin/defaults write /Library/LaunchDaemons/com.deploystudio.finalizeScript Disabled -bool YES
    /bin/chmod 644 /Library/LaunchDaemons/com.deploystudio.finalizeScript.plist
  else
    /usr/bin/defaults write /Library/LaunchAgents/com.deploystudio.finalizeScript Disabled -bool YES
    /bin/chmod 644 /Library/LaunchAgents/com.deploystudio.finalizeScript.plist
    /usr/bin/defaults write /Library/LaunchAgents/com.deploystudio.FinalizeApp Disabled -bool YES
    /bin/chmod 644 /Library/LaunchAgents/com.deploystudio.FinalizeApp.plist
  fi

  # restore initial system configuration
  restore_initial_config

  # reboot
  custom_logger "end"
  /sbin/reboot -l
  exit 0
fi

#
# disable indexing while working
#
custom_logger "disabling Spotlight indexing..."
/usr/bin/mdutil -i off / >/dev/null 2>&1

#
# Update dyld shared caches if needed
#
DYLD_SHARED_CACHES=`ls /var/db/dyld/dyld* 2>/dev/null`
if [ -z "${DYLD_SHARED_CACHES}" ]
then
  custom_logger "updating dyld shared caches..."
  /usr/bin/update_dyld_shared_cache -force
fi

#
# Rebuild xpchelper cache if needed
#
if [ -e /usr/libexec/xpchelper ] && [ ! -e /System/Library/Caches/com.apple.xpchelper.cache ]
then
  custom_logger "rebuilding xpchelper cache..."
  /usr/libexec/xpchelper --rebuild-cache
fi

#
# Detect unregistered network services
#
/usr/sbin/networksetup -detectnewhardware

#
# Blocks until all network services have completed configuring, or have timed out.
#
/usr/sbin/ipconfig waitall

#
# Run basic configuration scripts in a logical order
#
exec_if_exists "/etc/deploystudio/bin/ds_time_setup.sh"
exec_if_exists "/etc/deploystudio/bin/ds_rename_computer.sh"
if [ ! -e /Library/Keychains/System.keychain ]
then
  /usr/sbin/systemkeychain -C
fi
if [ ! -e "/etc/deploystudio/bin/.ds_finalize.calls" ]
then
  exec_if_exists "/usr/libexec/configureLocalKDC"
fi
exec_if_exists "/etc/deploystudio/bin/ds_add_local_users_main.sh"

#
# Run remaining scripts matching to the workflow definition order
#
REMAINING_DS_SCRIPTS=`/bin/ls -tr /etc/deploystudio/bin/ds_*.sh /etc/deploystudio/bin/ds_*.pl 2>/dev/null`
if [ -n "${REMAINING_DS_SCRIPTS}" ]
then
  for DS_SCRIPT_PATH in ${REMAINING_DS_SCRIPTS}
  do
    SCRIPT_BASE_NAME=`basename "${DS_SCRIPT_PATH}"`

    if [ "${SCRIPT_BASE_NAME}" = "ds_software_update.pl" ]
    then
      if [ -e "/etc/deploystudio/bin/.ds_software_update.calls" ] && [ `/usr/bin/wc -l "/etc/deploystudio/bin/.ds_software_update.calls" | /usr/bin/awk '{ print $1 }'` -gt 3 ]
      then
        custom_logger "this computer has already rebooted 3 times because of Apple software update, ignoring script."
        rm -Pf "/etc/deploystudio/bin/ds_software_update.pl"
      else
        "${DS_SCRIPT_PATH}"
        SUS_RESULT=${?}
        if [ ${SUS_RESULT} -ne 200 ]
        then
          if [ ${SUS_RESULT} -ne 100 ]
          then
            /bin/echo `/bin/date` >> "/etc/deploystudio/bin/.ds_software_update.calls"
          fi
          custom_logger "reboot required after running Apple software update packages installation, system will automatically reboot."
          custom_logger "end"
          /sbin/reboot -l
          exit 0
        fi
      fi
    elif [ "${SCRIPT_BASE_NAME}" != "${SCRIPT_NAME}" ] && [ "${SCRIPT_BASE_NAME}" != "ds_enable_ard_agent.sh" ]
	then
      exec_if_exists "${DS_SCRIPT_PATH}"
    fi
  done
fi

# enable ard agent
exec_if_exists "/etc/deploystudio/bin/ds_enable_ard_agent.sh"

# disable iCloud and gestures demos
if [ `sw_vers -productVersion | awk -F. '{ print $2 }'` -ge 7 ]
then
  SYS_VERS=`sw_vers -productVersion`
  custom_logger "Disabling iCloud and gestures preference panes auto-launch at first login."

  defaults write /Library/Preferences/com.apple.SetupAssistant RegisteredVersion "${SYS_VERS}"

  for USER_TEMPLATE in "/System/Library/User Template"/*
  do
    defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.SetupAssistant DidSeeCloudSetup -bool TRUE
    defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.SetupAssistant DidSeeSiriSetup -bool TRUE
    defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.SetupAssistant GestureMovieSeen none
    defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.SetupAssistant LastSeenCloudProductVersion "${SYS_VERS}"
  done

  for USER_HOME in /Users/*
  do
    USER_UID=`basename "${USER_HOME}"`
    if [ ! "${USER_UID}" = "Shared" ] 
    then 
      if [ ! -d "${USER_HOME}"/Library/Preferences ]
      then
        mkdir -p "${USER_HOME}"/Library/Preferences
        chown "${USER_UID}" "${USER_HOME}"/Library
        chown "${USER_UID}" "${USER_HOME}"/Library/Preferences
      fi
      if [ -d "${USER_HOME}"/Library/Preferences ]
      then
        defaults write "${USER_HOME}"/Library/Preferences/com.apple.SetupAssistant DidSeeCloudSetup -bool TRUE
        defaults write "${USER_HOME}"/Library/Preferences/com.apple.SetupAssistant DidSeeSiriSetup -bool TRUE
        defaults write "${USER_HOME}"/Library/Preferences/com.apple.SetupAssistant GestureMovieSeen none
        defaults write "${USER_HOME}"/Library/Preferences/com.apple.SetupAssistant LastSeenCloudProductVersion "${SYS_VERS}"
        chown "${USER_UID}" "${USER_HOME}"/Library/Preferences/com.apple.SetupAssistant.plist
      fi
    fi
  done
fi

# prepare for cleanup
if [ -e /etc/deploystudio/ds_packages ]
then
  # Delete packages folder if empty
  /bin/rmdir /etc/deploystudio/ds_packages &>/dev/null
  if [ ${?} -eq 0 ]
  then
    # restore initial system configuration
    restore_initial_config
    final_cleanup "reboot required by packages installation, system will automatically reboot in ${REBOOT_DELAY}s."
    /sbin/reboot -l
    exit 0
  else
    /bin/echo `/bin/date` >> "/etc/deploystudio/bin/.ds_finalize.calls"
    custom_logger "failed to remove the /etc/deploystudio/ds_packages folder, system will automatically reboot."
    custom_logger "end"
    /sbin/reboot -l
    exit 0
  fi
else
  # restore initial system configuration
  restore_initial_config

  # cleanup
  final_cleanup "Finalize script completed, system will automatically reboot."
  /sbin/reboot -l
fi

exit 0