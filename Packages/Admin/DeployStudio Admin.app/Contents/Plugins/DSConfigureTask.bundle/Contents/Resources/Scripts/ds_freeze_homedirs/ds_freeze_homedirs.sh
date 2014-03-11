#!/bin/sh

SCRIPT_NAME=`/usr/bin/basename "${0}"`

echo "${SCRIPT_NAME} - v1.2 ("`date`")"

# Defaults
BACKUP_FOLDER=/private/dss_homedirs_ref
INCLUDE_SHARED_FOLDER="NO"

# Functions
am_i_root() {
  if [ ${UID} != 0 ]
  then
    echo "  Sorry, only root can run this script !"
    exit 1
  fi
}

restore_user_homedirectory() {
  USER_SHORTNAME=${1}

  if [ -e "${BACKUP_FOLDER}/${USER_SHORTNAME}" ] && [ -e "${BACKUP_FOLDER}/${USER_SHORTNAME}/.dss.disable.backup" ]
  then
    echo "  User home directory \"/Users/${USER_SHORTNAME}\" backup disabled"
  else
    if [ -e "${BACKUP_FOLDER}/${USER_SHORTNAME}" ] && [ -e "${BACKUP_FOLDER}/${USER_SHORTNAME}/.dss.delete.backup" ]
    then
      echo "  Deleting user home directory \"/Users/${USER_SHORTNAME}\" backup"
      rm -rf "${BACKUP_FOLDER}/${USER_SHORTNAME}"
      echo "  Backup deleted"
    fi
    if [ -e "${BACKUP_FOLDER}/${USER_SHORTNAME}" ] && [ -e "${BACKUP_FOLDER}/${USER_SHORTNAME}/.dss.update.backup" ]
    then
      rm "${BACKUP_FOLDER}/${USER_SHORTNAME}/.dss.update.backup"
      echo "  Updating backup of user home directory \"/Users/${USER_SHORTNAME}\""
      rsync -a --delete "/Users/${USER_SHORTNAME}" "${BACKUP_FOLDER}/"
      echo "  Backup update complete"
    elif [ -e "${BACKUP_FOLDER}/${USER_SHORTNAME}" ]
    then
	  echo "  Restoring user home directory \"/Users/${USER_SHORTNAME}\""
      rsync -a --delete "${BACKUP_FOLDER}/${USER_SHORTNAME}" "/Users/"
      echo "  Restore complete"
    else
      if [ ! -e "${BACKUP_FOLDER}" ]
	  then
        echo "  Creating backup folder \"${BACKUP_FOLDER}\""
        mkdir -p "${BACKUP_FOLDER}"
        chown root:wheel "${BACKUP_FOLDER}"
        chmod 755 "${BACKUP_FOLDER}"
      fi
      if [ -e "/Users/${USER_SHORTNAME}" ]
	  then
	    echo "  Backing up user home directory \"/Users/${USER_SHORTNAME}\""
        ditto --rsrc "/Users/${USER_SHORTNAME}" "${BACKUP_FOLDER}/${USER_SHORTNAME}"
	    echo "  Backup complete"
      fi
    fi
  fi	
}

# main
am_i_root

if [ -e "/Library/LaunchAgents/com.deploystudio.finalizeScript.plist" ]
then
  echo "  Sorry, DeployStudio finalize agent is still running!"
  echo "  Will retry at next boot..."
  exit 1
fi

if [ "${1}" == "--include-shared-folder" ]
then
  INCLUDE_SHARED_FOLDER="YES"
fi

for HOME_DIRECTORY_PATH in /Users/*
do
  HOME_DIRECTORY=`basename "${HOME_DIRECTORY_PATH}"`
  if [ "${HOME_DIRECTORY}" != "Shared" ] || [ "${INCLUDE_SHARED_FOLDER}" == "YES" ]
  then
    restore_user_homedirectory "${HOME_DIRECTORY}"
  fi
done

exit 0
