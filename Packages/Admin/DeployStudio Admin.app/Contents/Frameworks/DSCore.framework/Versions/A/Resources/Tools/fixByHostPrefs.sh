#!/bin/sh

echo "fixByHostPrefs.sh - v1.11 ("`date`")"

_HOMES=("/Volumes/${1}/Users" "/Volumes/${1}/System/Library/User Template")
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

for _INDEX in 0 1
do
  if [ -d "${_HOMES[$_INDEX]}" ]
  then
    _USERHOMES=`ls -A "${_HOMES[$_INDEX]}"`
    for _USERHOME in ${_USERHOMES}
    do
      _HOME=${_HOMES[${_INDEX}]}/${_USERHOME}/Library/Preferences
      if [ -d "${_HOME}" ]
      then
        rm "${_HOME}"/.*.lockfile "${_HOME}"/*.lockfile &>/dev/null
      fi
      _HOME=${_HOME}/ByHost
      if [ -d "${_HOME}" ]
	  then
        rm "${_HOME}"/.*.lockfile "${_HOME}"/*.lockfile &>/dev/null
        rm "${_HOME}"/com.apple.NetworkBrowserAgent.* &>/dev/null
        cd "${_HOME}"
		fix_byhost_folder_preferences
      fi
    done
  fi
done

_HOME="/Volumes/${1}/var/root/Library/Preferences/ByHost"
if [ -d "${_HOME}" ]
then
  cd "${_HOME}"
  fix_byhost_folder_preferences
fi

# Check other user home directories. 
# The following code will replace the previous lines as soon as we stop 10.4 support.
_DS_USERS_PATH="/Volumes/${1}/var/db/dslocal/nodes/Default/users/"
if [ -e "${_DS_USERS_PATH}" ]
then
  cd "${_DS_USERS_PATH}"
  for EXTRA_USER in *.plist
  do 
    if [ ${EXTRA_USER:0:1} != "_" ]
    then 
      EXTRA_USER_RECORD=`echo ${EXTRA_USER} | sed s/.plist//`
      EXTRA_USER_HOME=`defaults read "${_DS_USERS_PATH}/${EXTRA_USER_RECORD}" home | awk -F\" '{ print $2 }' | tr -d "\n"`
      EXTRA_USER_PREFS_PATH="/Volumes/${1}/${EXTRA_USER_HOME}/Library/Preferences"
      if [ -d "${EXTRA_USER_PREFS_PATH}" ]
      then
        rm "${EXTRA_USER_PREFS_PATH}"/.*.lockfile "${EXTRA_USER_PREFS_PATH}"/*.lockfile &>/dev/null
      fi
      EXTRA_USER_BYHOST_PATH="${EXTRA_USER_PREFS_PATH}/ByHost"
      if [ -e "${EXTRA_USER_BYHOST_PATH}" ] && [ "${EXTRA_USER_HOME}" != "/var/empty" ] && [ "${EXTRA_USER_HOME}" != "/var/root" ] && [ "${EXTRA_USER_HOME:0:7}" != "/Users/" ]
      then
        rm "${EXTRA_USER_BYHOST_PATH}"/.*.lockfile "${EXTRA_USER_BYHOST_PATH}"/*.lockfile &>/dev/null
        rm "${EXTRA_USER_BYHOST_PATH}"/com.apple.NetworkBrowserAgent.* &>/dev/null
	    cd "${EXTRA_USER_BYHOST_PATH}"
		fix_byhost_folder_preferences
		cd "/Volumes/${1}/var/db/dslocal/nodes/Default/users/"
      fi
    fi
  done
fi

echo "${_RENAMEDFILES} files were renamed"

echo "fixByHostPrefs.sh - end"

exit 0
