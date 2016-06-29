#!/bin/sh

SCRIPT_NAME=`/usr/bin/basename "${0}"`

echo "${SCRIPT_NAME} - v1.5 ("`date`")"

#
# Enable the ARD agent
#
KICKSTART="/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart"
CONFIGURE_PARAMS="-configure -access -on"
RESTART_PARAMS="-activate -restart -agent -console"

if [ -n "__ADMIN_GROUP__" ]
then
  CONFIGURE_PARAMS="${CONFIGURE_PARAMS} -privs -none -allowAccessFor -specifiedUsers"
  /usr/sbin/dseditgroup -o create com.apple.local.ard_admin 2>&1
  /usr/sbin/dseditgroup -o edit -a "__ADMIN_GROUP__" -t group com.apple.local.ard_admin 2>&1
else
  CONFIGURE_PARAMS="${CONFIGURE_PARAMS} -privs -all -allowAccessFor -allUsers"
fi

ATTEMPTS=0
MAX_ATTEMPTS=12
while [ "_${SUCCESS}" = "_" ]
do
  if [ ${ATTEMPTS} -le ${MAX_ATTEMPTS} ]
  then
    echo "Configuring ARD agent..." 2>&1
    ${KICKSTART} ${CONFIGURE_PARAMS}
    if [ ${?} -eq 0 ]
    then
      ${KICKSTART} ${RESTART_PARAMS}
      SUCCESS="YES"
    else
      echo "An error occured while setup ARD agent, new attempt in 10 seconds..." 2>&1
      sleep 10
      ATTEMPTS=`/bin/expr ${ATTEMPTS} + 1`
    fi
  fi
done

if [ "_${SUCCESS}" = "_YES" ]
then
  #
  # Self removal
  #
  rm -f "${0}"
else
  echo "ARD agent configuration failed, will retry on next boot!"
fi

exit 0