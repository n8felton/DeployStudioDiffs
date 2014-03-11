#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
SCRIPT_PATH=`dirname "${0}"`

echo "${SCRIPT_NAME} - v1.17 ("`date`")"

if [ ${#} -ne 1 ]
then
  echo "Command: ${SCRIPT_NAME} ${*}"
  echo "Usage: ${SCRIPT_NAME} <volume name>"
  echo "RuntimeAbortWorkflow: missing arguments!"
  exit 1
fi

if [ "${1}" = "/" ]
then
  VOLUME_PATH=/
else
  VOLUME_PATH=/Volumes/${1}
fi

if [ ! -e "${VOLUME_PATH}" ]
then
  echo "Command: ${SCRIPT_NAME} ${*}"
  echo "Usage: ${SCRIPT_NAME} <volume name>"
  echo "RuntimeAbortWorkflow: \"${VOLUME_PATH}\" volume not found!"
  exit 1
fi

if [ -e "${VOLUME_PATH}"/etc/deploystudio/Applications/Finalize.app ]
then
  echo "Finalize resources already installed, skipping..."
  # make a 2s pause to warrant post-install tasks execution order
  sleep 2
  echo "${SCRIPT_NAME} - end"
  exit 0
fi

VOLUME_SYS=`defaults read "${VOLUME_PATH}"/System/Library/CoreServices/SystemVersion ProductVersion | awk -F. '{ print $2 }'`
if [ -z "${VOLUME_SYS}" ]
then
  VOLUME_SYS=`sw_vers -productVersion | awk -F. '{ print $2 }'`
fi

OWNERS_STATUS=`diskutil info "${VOLUME_PATH}" | tr -d ' ' | grep 'Owners:Disabled'`
if [ -n "${OWNERS_STATUS}" ]
then
  if [ `sw_vers -productVersion | awk -F. '{ print $2 }'` -gt 5 ]
  then
    diskutil enableOwnership "${VOLUME_PATH}"
  else
    /usr/sbin/vsdbutil -a "${VOLUME_PATH}"
  fi
fi

rm -f "${VOLUME_PATH}"/var/db/dyld/dyld* 2>/dev/null

if [ ! -e "${VOLUME_PATH}/Library/LaunchDaemons" ]
then
  mkdir -p "${VOLUME_PATH}"/Library/LaunchDaemons
  chmod 775 "${VOLUME_PATH}"/Library
  chown root:admin "${VOLUME_PATH}"/Library
  chmod 755 "${VOLUME_PATH}"/Library/LaunchDaemons
  chown root:wheel "${VOLUME_PATH}"/Library/LaunchDaemons
fi

if [ ! -e "${VOLUME_PATH}/Library/LaunchAgents" ]
then
  mkdir -p "${VOLUME_PATH}"/Library/LaunchAgents
  chmod 775 "${VOLUME_PATH}"/Library
  chown root:admin "${VOLUME_PATH}"/Library
  chmod 755 "${VOLUME_PATH}"/Library/LaunchAgents
  chown root:wheel "${VOLUME_PATH}"/Library/LaunchAgents
fi

if [ ! -e "${VOLUME_PATH}/etc/deploystudio/bin" ]
then
  mkdir -p "${VOLUME_PATH}"/etc/deploystudio/bin
  chmod 755 "${VOLUME_PATH}"/etc/deploystudio "${VOLUME_PATH}"/etc/deploystudio/bin
  chown root:wheel "${VOLUME_PATH}"/etc/deploystudio "${VOLUME_PATH}"/etc/deploystudio/bin
fi

if [ ! -e "${VOLUME_PATH}/etc/deploystudio/sbin" ]
then
  mkdir -p "${VOLUME_PATH}"/etc/deploystudio/sbin
  chmod 755 "${VOLUME_PATH}"/etc/deploystudio "${VOLUME_PATH}"/etc/deploystudio/sbin
  chown root:wheel "${VOLUME_PATH}"/etc/deploystudio "${VOLUME_PATH}"/etc/deploystudio/sbin
fi

if [ ! -e "${VOLUME_PATH}/etc/deploystudio/etc" ]
then
  mkdir -p "${VOLUME_PATH}"/etc/deploystudio/etc
  chmod 755 "${VOLUME_PATH}"/etc/deploystudio "${VOLUME_PATH}"/etc/deploystudio/etc
  chown root:wheel "${VOLUME_PATH}"/etc/deploystudio "${VOLUME_PATH}"/etc/deploystudio/etc

  if [ -e /System/Library/CoreServices/DefaultDesktop.jpg ]
  then
    cp /System/Library/CoreServices/DefaultDesktop.jpg "${VOLUME_PATH}"/etc/deploystudio/etc/
    chmod 644 "${VOLUME_PATH}"/etc/deploystudio/etc/DefaultDesktop.jpg
    chown root:wheel "${VOLUME_PATH}"/etc/deploystudio/etc/DefaultDesktop.jpg
  fi
fi

if [ ${VOLUME_SYS} -gt 4 ]
then
  if [ ! -e "${VOLUME_PATH}/etc/deploystudio/Applications" ]
  then
    mkdir -p "${VOLUME_PATH}"/etc/deploystudio/Applications
    chmod 755 "${VOLUME_PATH}"/etc/deploystudio "${VOLUME_PATH}"/etc/deploystudio/Applications
    chown root:wheel "${VOLUME_PATH}"/etc/deploystudio "${VOLUME_PATH}"/etc/deploystudio/Applications
  fi

  if [ ! -e "${VOLUME_PATH}"/etc/deploystudio/Applications/Finalize.app ]
  then
    cp -R "${SCRIPT_PATH}"/Finalize.app "${VOLUME_PATH}"/etc/deploystudio/Applications/
    chmod 700 "${VOLUME_PATH}"/etc/deploystudio/Applications/Finalize.app/Contents/MacOS/Finalize
    chown -R root:wheel "${VOLUME_PATH}"/etc/deploystudio/Applications/Finalize.app
  fi

  if [ ! -e "${VOLUME_PATH}"/Library/LaunchAgents/com.deploystudio.FinalizeApp.plist ]
  then
    cp "${SCRIPT_PATH}"/com.deploystudio.FinalizeApp.plist "${VOLUME_PATH}"/Library/LaunchAgents/
    chmod 644 "${VOLUME_PATH}"/Library/LaunchAgents/com.deploystudio.FinalizeApp.plist
    chown root:wheel "${VOLUME_PATH}"/Library/LaunchAgents/com.deploystudio.FinalizeApp.plist
  fi

  if [ ! -e "${VOLUME_PATH}"/Library/LaunchAgents/com.deploystudio.finalizeScript.plist ]
  then
    cp "${SCRIPT_PATH}"/com.deploystudio.finalizeScript.plist "${VOLUME_PATH}"/Library/LaunchAgents/
    chmod 644 "${VOLUME_PATH}"/Library/LaunchAgents/com.deploystudio.finalizeScript.plist
    chown root:wheel "${VOLUME_PATH}"/Library/LaunchAgents/com.deploystudio.finalizeScript.plist
  fi
fi

if [ ! -e "${VOLUME_PATH}"/Library/LaunchDaemons/com.deploystudio.finalizeCleanup.plist ]
then
  cp "${SCRIPT_PATH}"/com.deploystudio.finalizeCleanup.plist "${VOLUME_PATH}"/Library/LaunchDaemons/
  chmod 644 "${VOLUME_PATH}"/Library/LaunchDaemons/com.deploystudio.finalizeCleanup.plist
  chown root:wheel "${VOLUME_PATH}"/Library/LaunchDaemons/com.deploystudio.finalizeCleanup.plist
fi

if [ ! -e "${VOLUME_PATH}"/etc/deploystudio/bin/ds_finalize.sh ]
then
  cp "${SCRIPT_PATH}"/ds_finalize.sh "${VOLUME_PATH}"/etc/deploystudio/bin
  chmod 700 "${VOLUME_PATH}"/etc/deploystudio/bin/ds_finalize.sh
  chown root:wheel "${VOLUME_PATH}"/etc/deploystudio/bin/ds_finalize.sh
fi

if [ ! -e "${VOLUME_PATH}"/etc/deploystudio/sbin/ds_finalize_cleanup.sh ]
then
  cp "${SCRIPT_PATH}"/ds_finalize_cleanup.sh "${VOLUME_PATH}"/etc/deploystudio/sbin/
  chmod 700 "${VOLUME_PATH}"/etc/deploystudio/sbin/ds_finalize_cleanup.sh
  chown root:wheel "${VOLUME_PATH}"/etc/deploystudio/sbin/ds_finalize_cleanup.sh
fi

AUTO_LOGIN_USER=`defaults read "${VOLUME_PATH}"/Library/Preferences/com.apple.loginwindow autoLoginUser 2>/dev/null`
if [ -n "${AUTO_LOGIN_USER}" ]
then
  if [ -e "${VOLUME_PATH}"/etc/kcpassword ]
  then
    mv "${VOLUME_PATH}"/etc/kcpassword "${VOLUME_PATH}"/etc/deploystudio/etc/
  fi
  defaults write  "${VOLUME_PATH}"/etc/deploystudio/etc/autoLoginUser autoLoginUser "${AUTO_LOGIN_USER}"
  defaults delete "${VOLUME_PATH}"/Library/Preferences/com.apple.loginwindow autoLoginUser 2>/dev/null
  chmod 644 "${VOLUME_PATH}"/Library/Preferences/com.apple.loginwindow.plist
  chown root:wheel "${VOLUME_PATH}"/Library/Preferences/com.apple.loginwindow.plist
fi

if [ ! -e "${VOLUME_PATH}"/var/db/.AppleSetupDone ]
then
  touch "${VOLUME_PATH}"/var/db/.AppleSetupDone
  touch "${VOLUME_PATH}"/var/db/.ds.delete.AppleSetupDone
fi

echo "${SCRIPT_NAME} - end"

exit 0
