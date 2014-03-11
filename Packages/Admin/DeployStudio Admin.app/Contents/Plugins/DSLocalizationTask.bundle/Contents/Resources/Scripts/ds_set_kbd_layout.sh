#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
SCRIPT_PATH=`dirname "${0}"`

echo "${SCRIPT_NAME} - v1.0 ("`date`")"

PLBUDDY=/usr/libexec/PlistBuddy

update_kdb_layout() {
  echo "Updating file '${1}'"
  ${PLBUDDY} -c "Delete :AppleCurrentKeyboardLayoutInputSourceID" "${1}" &>/dev/null
  if [ ${?} -eq 0 ] || [ -n "${4}" ]
  then
    ${PLBUDDY} -c "Add :AppleCurrentKeyboardLayoutInputSourceID string com.apple.keylayout.${2}" "${1}"
  fi

  for SOURCE in AppleDefaultAsciiInputSource AppleCurrentAsciiInputSource AppleCurrentInputSource AppleEnabledInputSources AppleSelectedInputSources
  do
    ${PLBUDDY} -c "Delete :${SOURCE}" "${1}" &>/dev/null
    if [ ${?} -eq 0 ] || [ -n "${4}" ]
    then
      ${PLBUDDY} -c "Add :${SOURCE} array" "${1}"
      ${PLBUDDY} -c "Add :${SOURCE}:0 dict" "${1}"
      ${PLBUDDY} -c "Add :${SOURCE}:0:InputSourceKind string 'Keyboard Layout'" "${1}"
      ${PLBUDDY} -c "Add :${SOURCE}:0:KeyboardLayout\ ID integer ${3}" "${1}"
      ${PLBUDDY} -c "Add :${SOURCE}:0:KeyboardLayout\ Name string '${2}'" "${1}"
    fi
  done
}

if [ ${#} -lt 3 ]
then
  echo "Command: ${SCRIPT_NAME} ${*}"
  echo "Usage: ${SCRIPT_NAME} <volume name> <name> <ID> [--include-homedirs]"
  echo "RuntimeAbortWorkflow: missing arguments!"
  exit 1
fi

if [ "${1}" = "/" ]
then
  VOLUME_PATH=
else
  VOLUME_PATH=/Volumes/${1}
fi

update_kdb_layout "${VOLUME_PATH}/Library/Preferences/com.apple.HIToolbox.plist" "${2}" "${3}" --force

if [ -d "${VOLUME_PATH}"/var/root/Library/Preferences ]
then
  cd "${VOLUME_PATH}"/var/root/Library/Preferences
  HITOOLBOX_FILES=`find . -name "com.apple.HIToolbox.*plist"`
  for HITOOLBOX_FILE in ${HITOOLBOX_FILES}
  do
    update_kdb_layout "${HITOOLBOX_FILE}" "${2}" "${3}" --force
  done
fi

if [ -n "${4}" ] && [ "${4}" = "--include-homedirs" ]
then
  for HOME in "${VOLUME_PATH}"/Users/*
  do
    if [ -d "${HOME}"/Library/Preferences ]
    then
      cd "${HOME}"/Library/Preferences
      HITOOLBOX_FILES=`find . -name "com.apple.HIToolbox.*plist"`
      for HITOOLBOX_FILE in ${HITOOLBOX_FILES}
      do
        update_kdb_layout "${HITOOLBOX_FILE}" "${2}" "${3}"
      done
    fi
  done
fi

echo "${SCRIPT_NAME} - end"

exit 0
