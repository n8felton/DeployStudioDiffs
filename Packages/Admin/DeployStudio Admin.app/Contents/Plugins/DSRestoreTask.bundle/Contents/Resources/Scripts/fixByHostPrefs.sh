#!/bin/sh

echo "fixByHostPrefs.sh - v1.12 ("`date`")"

_MACADDR=`/sbin/ifconfig en0 | grep -w ether | awk '{ gsub(":", ""); print $2 }'`
_HOSTUUID=`ioreg -rd1 -c IOPlatformExpertDevice | awk -F= '/(UUID)/ { gsub("[ \"]", ""); print $2 }'`
_RENAMEDFILES=0
_DEBUG=0

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
    _RENAMEDFILES=`expr ${_RENAMEDFILES} + 1`
    if [ ${_DEBUG} -eq 0 ]
    then
      cp -p "${1}" "${_MACADDR_RENAMEDFILE}"
	  if [ ! -e "${_HOSTUUID_RENAMEDFILE}" ]
	  then
        cp -p "${1}" "${_HOSTUUID_RENAMEDFILE}"
	  fi
      /usr/bin/srm -mf "${1}"
    fi
  fi
}

rename_uuid_byhost_preference_file() {
  _HOSTUUID_RENAMEDFILE=`echo "${1}" | sed "s/\.........-....-....-....-............\.plist$/.${_HOSTUUID}.plist/g"`
  if [ "${1}" != "${_HOSTUUID_RENAMEDFILE}" ]
  then
    echo "Renaming file '"${1}"' to '"${_HOSTUUID_RENAMEDFILE}"'"
    _RENAMEDFILES=`expr ${_RENAMEDFILES} + 1`
    if [ ${_DEBUG} -eq 0 ]
    then
      cp -p "${1}" "${_HOSTUUID_RENAMEDFILE}"
      /usr/bin/srm -mf "${1}"
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
    cd "${1}/ByHost"
	fix_byhost_folder_preferences
  fi
}

# Check User Templates first
if [ -d "/Volumes/${1}/System/Library/User Template" ]
then
  find "/Volumes/${1}/System/Library/User Template" -name "Preferences" -type d | while read PREFS_FOLDER; do fix_preferences_folder "${PREFS_FOLDER}"; done
fi

# Check other user home directories. 
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
		cd "/Volumes/${1}/var/db/dslocal/nodes/Default/users/"
      fi
    fi
  done
fi

echo "${_RENAMEDFILES} files were renamed"

echo "fixByHostPrefs.sh - end"

exit 0