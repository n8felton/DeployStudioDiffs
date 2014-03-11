#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
SCRIPT_PATH=`dirname "${0}"`

echo "${SCRIPT_NAME} - v1.0 ("`date`")"

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

nvram -d boot-args
defaults write "${VOLUME_PATH}"/System/Library/LaunchDaemons/com.apple.loginwindow Disabled -bool false
chmod 644 "${VOLUME_PATH}"/System/Library/LaunchDaemons/com.apple.loginwindow.plist
chown root:wheel "${VOLUME_PATH}"/System/Library/LaunchDaemons/com.apple.loginwindow.plist

defaults write "${VOLUME_PATH}"/System/Library/LaunchDaemons/com.apple.WindowServer Disabled -bool false
chmod 644 "${VOLUME_PATH}"/System/Library/LaunchDaemons/com.apple.WindowServer.plist
chown root:wheel "${VOLUME_PATH}"/System/Library/LaunchDaemons/com.apple.WindowServer.plist

defaults delete "${VOLUME_PATH}"/var/db/launchd.db/com.apple.launchd/overrides com.apple.loginwindow &>/dev/null
defaults delete "${VOLUME_PATH}"/var/db/launchd.db/com.apple.launchd/overrides com.apple.WindowServer &>/dev/null

echo "${SCRIPT_NAME} - end"

exit 0
