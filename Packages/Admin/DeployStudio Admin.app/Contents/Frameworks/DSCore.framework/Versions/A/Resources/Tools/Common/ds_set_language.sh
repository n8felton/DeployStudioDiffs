#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
SCRIPT_PATH=`dirname "${0}"`

echo "${SCRIPT_NAME} - v1.0 ("`date`")"

PLBUDDY=/usr/libexec/PlistBuddy

update_language() {
  echo "Updating language preference in '${1}'"

  ${PLBUDDY} -c "Delete :AppleLanguages" "${1}" &>/dev/null
  if [ ${?} -eq 0 ] || [ -n "${3}" ]
  then
    ${PLBUDDY} -c "Add :AppleLanguages array" "${1}"
    ${PLBUDDY} -c "Add :AppleLanguages:0 string '${2}'" "${1}"
  fi
}

if [ ${#} -lt 2 ]
then
  echo "Command: ${SCRIPT_NAME} ${*}"
  echo "Usage: ${SCRIPT_NAME} <volume name> <languagecode> [--include-homedirs]"
  echo "RuntimeAbortWorkflow: missing arguments!"
  exit 1
fi

if [ "${1}" = "/" ]
then
  VOLUME_PATH=
else
  VOLUME_PATH=/Volumes/${1}
fi

update_language "${VOLUME_PATH}/Library/Preferences/.GlobalPreferences.plist" "${2}" --force

if [ -d "${VOLUME_PATH}"/var/root/Library/Preferences ]
then
  cd "${VOLUME_PATH}"/var/root/Library/Preferences
  GLOBALPREFERENCES_FILES=`find . -name "\.GlobalPreferences.*plist"`
  for GLOBALPREFERENCES_FILE in ${GLOBALPREFERENCES_FILES}
  do
    update_language "${GLOBALPREFERENCES_FILE}" "${2}" --force
  done
fi

if [ -n "${3}" ] && [ "${3}" = "--include-homedirs" ]
then
  for HOME in "${VOLUME_PATH}"/Users/*
  do
    if [ -d "${HOME}"/Library/Preferences ]
    then
      cd "${HOME}"/Library/Preferences
      GLOBALPREFERENCES_FILES=`find . -name "\.GlobalPreferences.*plist"`
      for GLOBALPREFERENCES_FILE in ${GLOBALPREFERENCES_FILES}
      do
        update_language "${GLOBALPREFERENCES_FILE}" "${2}"
      done
    fi
  done
fi

echo "${SCRIPT_NAME} - end"

exit 0
