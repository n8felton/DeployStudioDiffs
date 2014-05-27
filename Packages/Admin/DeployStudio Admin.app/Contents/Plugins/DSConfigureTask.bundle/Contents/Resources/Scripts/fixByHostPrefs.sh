#!/bin/sh

echo "fixByHostPrefs.sh - v1.14 ("`date`")"

_MACADDR=`/sbin/ifconfig en0 | grep -w ether | awk '{ gsub(":", ""); print $2 }'`
_HOSTUUID=`ioreg -rd1 -c IOPlatformExpertDevice | awk -F= '/(UUID)/ { gsub("[ \"]", ""); print $2 }'`
_DEBUG=0

_COUNTER_FILE=`mktemp /tmp/fixByHostPrefs.XXXXXX` 

if [ "${_HOSTUUID:0:8}" = "00000000" ]
then
  _HOSTUUID=`echo ${_HOSTUUID:24:12} | tr [A-Z] [a-z]`
  if [ ${#_HOSTUUID} -ne 12 ]
  then
    _HOSTUUID=${_MACADDR}
  fi
fi

rename_macaddr_byhost_preference_file() {
  _MACADDR_RENAMEDFILE=`echo "${1}" | sed "s/\.............\.plist$/.${_MACADDR}.plist/g"`
  if [ "${1}" != "${_MACADDR_RENAMEDFILE}" ]
  then
    _HOSTUUID_RENAMEDFILE=`echo "${1}" | sed "s/\.............\.plist$/.${_HOSTUUID}.plist/g"`
    echo "Renaming file '"${1}"' to '"${_MACADDR_RENAMEDFILE}"' and '"${_HOSTUUID_RENAMEDFILE}"'"
    (( _RENAMEDFILES++ ))
    if [ ${_DEBUG} -eq 0 ]
    then
      mv "${1}" "${_MACADDR_RENAMEDFILE}"
      if [ ! -e "${_HOSTUUID_RENAMEDFILE}" ]
      then
        mv "${_MACADDR_RENAMEDFILE}" "${_HOSTUUID_RENAMEDFILE}"
      fi
    fi
  fi
}

rename_uuid_byhost_preference_file() {
  _HOSTUUID_RENAMEDFILE=`echo "${1}" | sed "s/\.........-....-....-....-............\.plist$/.${_HOSTUUID}.plist/g"`
  if [ "${1}" != "${_HOSTUUID_RENAMEDFILE}" ]
  then
    echo "Renaming file '"${1}"' to '"${_HOSTUUID_RENAMEDFILE}"'"
    (( _RENAMEDFILES++ ))
    if [ ${_DEBUG} -eq 0 ]
    then
      mv "${1}" "${_HOSTUUID_RENAMEDFILE}"
    fi
  fi
}

fix_byhost_folder_preferences() {
  # Cleanup file locks
  rm .*.lockfile *.lockfile &>/dev/null

  # Delete computer specific files
  rm com.apple.NetworkBrowserAgent.* &>/dev/null
  
  # Rename preference files
  for _FILE in *.????????-????-????-????-????????????.plist
  do
    if [ "${_FILE}" != '*.????????-????-????-????-????????????.plist' ]
    then
      rename_uuid_byhost_preference_file "${_FILE}"
    fi
  done

  for _FILE in .*.????????-????-????-????-????????????.plist
  do
    if [ "${_FILE}" != '.*.????????-????-????-????-????????????.plist' ]
    then
      rename_uuid_byhost_preference_file "${_FILE}"
    fi
  done

  for _FILE in .*.????????????.plist
  do
    if [ "${_FILE}" != '.*.????????????.plist' ]
    then
      rename_macaddr_byhost_preference_file "${_FILE}"
    fi
  done

  for _FILE in *.????????????.plist
  do
    if [ "${_FILE}" != '*.????????????.plist' ]
    then
      rename_macaddr_byhost_preference_file "${_FILE}"
    fi
  done
}

fix_preferences_folder() {
  rm "${1}"/.*.lockfile "${1}"/*.lockfile &>/dev/null
  if [ -d "${1}/ByHost" ]
  then
    echo "Moving to directory: '${1}/ByHost'" 
    _RENAMEDFILES=0 
    cd "${1}/ByHost"
    fix_byhost_folder_preferences
    _COUNTER=`cat "${_COUNTER_FILE}"`
     expr ${_COUNTER} + ${_RENAMEDFILES} > "${_COUNTER_FILE}"
  fi
}

# Init counter
echo 0 > "${_COUNTER_FILE}"

# Check User Templates first
if [ -d "/Volumes/${1}/System/Library/User Template" ]
then
  find "/Volumes/${1}/System/Library/User Template" -name "Preferences" -type d | while read PREFS_FOLDER; do fix_preferences_folder "${PREFS_FOLDER}"; done
fi

# Check other user home directories
_DS_USERS_PATH="/Volumes/${1}/var/db/dslocal/nodes/Default/users"
if [ -d "${_DS_USERS_PATH}" ]
then
  cd "${_DS_USERS_PATH}"
  for EXTRA_USER in *.plist
  do 
    if [ ${EXTRA_USER:0:1} != "_" ]
    then 
      EXTRA_USER_RECORD=`echo ${EXTRA_USER} | sed s/.plist//`
      EXTRA_USER_HOME=`defaults read "${_DS_USERS_PATH}/${EXTRA_USER_RECORD}" home | awk -F\" '{ print $2 }' | tr -d "\n"`
      if [ "${EXTRA_USER_HOME}" != "/var/empty" ]
      then
        find "/Volumes/${1}${EXTRA_USER_HOME}/Library" -name "Preferences" -type d | while read PREFS_FOLDER; do fix_preferences_folder "${PREFS_FOLDER}"; done
        cd "${_DS_USERS_PATH}"
      fi
    fi
  done
fi

# Check locationd prefs
if [ -d "/Volumes/${1}/private/var/db/locationd" ]
then
  find "/Volumes/${1}/private/var/db/locationd" -name "Preferences" -type d | while read PREFS_FOLDER; do fix_preferences_folder "${PREFS_FOLDER}"; done
fi

_COUNTER=`cat "${_COUNTER_FILE}"`
echo "${_COUNTER} files were renamed"
rm "${_COUNTER_FILE}"

echo "fixByHostPrefs.sh - end"

exit 0