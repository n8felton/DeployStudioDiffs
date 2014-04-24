#!/bin/sh

# disable history characters
histchars=

SCRIPT_NAME=`basename "${0}"`

echo "${SCRIPT_NAME} - v1.18 ("`date`")"

# Usage: ${SCRIPT_NAME} $1 $2 $3 [$4 $5 $6 $7]
# $1 -> realname
# $2 -> shortname
# $3 -> password
# $4 -> admin (YES/NO)
# $5 -> hidden (YES/NO)
# $6 -> localization (English, French, etc...)
# $7 -> uidNumber

#
# create the default user
#
USER_REALNAME=${1}
USER_SHORTNAME=${2}
USER_PASSWORD=${3}
USER_ADMIN=${4}
USER_HIDDEN=${5}
USER_LOCALE=${6}
USER_UID=${7}

if [ "_YES" == "_${USER_HIDDEN}" ]
then
  USER_HOME="/var/.home/${USER_SHORTNAME}"
  if [ ! -d "/var/.home" ]
  then
    mkdir "/var/.home"
	chown root:admin "/var/.home"
	chmod 775 "/var/.home"
  fi
else
  USER_HOME="/Users/${USER_SHORTNAME}"
fi

if [ -n "${USER_SHORTNAME}" ]
then
  SAME_UID="YES"
  if [ -n "${USER_UID}" ]
  then
    SAME_UID=`dscl /Local/Default -list /Users uid | awk '{ print "+"$2"+" }' | grep "+${USER_UID}+"`
  fi
  if [ -n "${SAME_UID}" ]
  then
    USER_UID=`dscl /Local/Default -list /Users uid | awk '{ print $2 }' | sort -n | tail -n 1`
    USER_UID=`expr ${USER_UID} + 1`
    if [ ${USER_UID} -lt 501 ]
    then
      USER_UID=501
    fi
  fi

  echo "  Creating user '${USER_SHORTNAME}' with uid=${USER_UID} !" 2>&1

  dscl /Local/Default -delete users/${USER_SHORTNAME} >/dev/null 2>&1
  dscl /Local/Default -create users/${USER_SHORTNAME}

  dscl /Local/Default -create users/${USER_SHORTNAME} uid           "${USER_UID}"
  dscl /Local/Default -create users/${USER_SHORTNAME} gid           20
  dscl /Local/Default -create users/${USER_SHORTNAME} GeneratedUID  `/usr/bin/uuidgen`
  dscl /Local/Default -create users/${USER_SHORTNAME} home          "${USER_HOME}"
  dscl /Local/Default -create users/${USER_SHORTNAME} shell         "/bin/bash"

  dscl /Local/Default -create users/${USER_SHORTNAME} _writers_UserCertificate "${USER_SHORTNAME}"
  dscl /Local/Default -create users/${USER_SHORTNAME} _writers_hint            "${USER_SHORTNAME}"
  dscl /Local/Default -create users/${USER_SHORTNAME} _writers_jpegphoto       "${USER_SHORTNAME}"
  dscl /Local/Default -create users/${USER_SHORTNAME} _writers_passwd          "${USER_SHORTNAME}"
  dscl /Local/Default -create users/${USER_SHORTNAME} _writers_picture         "${USER_SHORTNAME}"
  dscl /Local/Default -create users/${USER_SHORTNAME} _writers_realname        "${USER_SHORTNAME}"

  if [ -e "/Library/User Pictures/Fun/Gingerbread Man.tif" ]
  then
    dscl /Local/Default -create users/${USER_SHORTNAME} picture "/Library/User Pictures/Fun/Gingerbread Man.tif"
  else
    if [ -e "/Library/User Pictures/Animals/Butterfly.tif" ]
    then
      dscl /Local/Default -create users/${USER_SHORTNAME} picture "/Library/User Pictures/Animals/Butterfly.tif"
    fi
  fi

  if [ -n "${USER_REALNAME}" ]
  then 
    dscl /Local/Default -create users/${USER_SHORTNAME} realname "${USER_REALNAME}"
  else
    dscl /Local/Default -create users/${USER_SHORTNAME} realname "${USER_SHORTNAME}"
  fi

  if [ -n "${USER_PASSWORD}" ]
  then 
    dscl /Local/Default -passwd /Users/${USER_SHORTNAME} "${USER_PASSWORD}"
  else
    dscl /Local/Default -passwd /Users/${USER_SHORTNAME} ""
  fi  

  if [ "_YES" = "_${USER_ADMIN}" ]
  then 
	echo "  Setting admin properties" 2>&1
    dscl /Local/Default -append groups/admin            users   "${USER_SHORTNAME}"
    # Enable all ARD privileges
    dscl /Local/Default -create users/${USER_SHORTNAME} naprivs -1073741569
  fi
  
  echo "  Creating local home directory" 2>&1
  HOMES_ROOT=`dirname "${USER_HOME}"`
  if [ -d  "${HOMES_ROOT}" ] && [ -d "/System/Library/User Template" ]
  then
    if [ -d "/System/Library/User Template/${USER_LOCALE}.lproj" ]
    then
	  ditto --rsrc "/System/Library/User Template/${USER_LOCALE}.lproj" "${USER_HOME}"
    else
	  ditto --rsrc "/System/Library/User Template/English.lproj" "${USER_HOME}"
    fi
  fi
  chown -R ${USER_UID}:20 "${USER_HOME}"

  if [ "_YES" == "_${USER_HIDDEN}" ]
  then
	defaults write /Library/Preferences/com.apple.loginwindow HiddenUsersList -array-add "${USER_SHORTNAME}"
	chmod 644 /Library/Preferences/com.apple.loginwindow.plist
	chown root:admin /Library/Preferences/com.apple.loginwindow.plist
  fi
fi
