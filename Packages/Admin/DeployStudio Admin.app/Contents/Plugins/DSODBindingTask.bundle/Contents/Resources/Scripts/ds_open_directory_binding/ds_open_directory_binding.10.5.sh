#!/bin/sh

# disable history characters
histchars=

SCRIPT_NAME=`basename "${0}"`

echo "${SCRIPT_NAME} - v1.34 ("`date`")"

#
# functions
#
is_ip_address() {
  IP_REGEX="\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b"
  IP_CHECK=`echo ${1} | egrep ${IP_REGEX}`
  if [ ${#IP_CHECK} -gt 0 ]
  then
    return 0
  else
    return 1
  fi
}

#
# Load script config
#
CONFIG_FILE=`echo "${0}" | sed s/\.sh$/\.plist/`
ODM_SERVER=`/usr/libexec/PlistBuddy -c "Print :server" "${CONFIG_FILE}" 2>/dev/null`
COMPUTER_ID=`/usr/libexec/PlistBuddy -c "Print :id" "${CONFIG_FILE}" 2>/dev/null`
ADMIN_LOGIN=`/usr/libexec/PlistBuddy -c "Print :admin" "${CONFIG_FILE}" 2>/dev/null`
ADMIN_PWD=`/usr/libexec/PlistBuddy -c "Print :password" "${CONFIG_FILE}" 2>/dev/null`
ENABLE_SSL=`/usr/libexec/PlistBuddy -c "Print :ssl" "${CONFIG_FILE}" 2>/dev/null`
ENABLE_TRUSTED_BINDING=`/usr/libexec/PlistBuddy -c "Print :trustedBinding" "${CONFIG_FILE}" 2>/dev/null`
CM_COMPUTER_GROUPS=`/usr/libexec/PlistBuddy -c "Print :cmComputerGroups" "${CONFIG_FILE}" 2>/dev/null`
CREATE_COMPUTER_GROUPS=`/usr/libexec/PlistBuddy -c "Print :createComputerGroups" "${CONFIG_FILE}" 2>/dev/null`

if [ -n "${ENABLE_SSL}" ] && [ "${ENABLE_SSL}" = 'YES' ]
then
  DSCONFIG_OPTIONS=-x
fi

#
# Wait for network services to be initialized
#
echo "Checking for the default route to be active..."
ATTEMPTS=0
MAX_ATTEMPTS=18
while ! (netstat -rn -f inet | grep -q default)
do
  if [ ${ATTEMPTS} -le ${MAX_ATTEMPTS} ]
  then
    echo "Waiting for the default route to be active..."
    sleep 10
    ATTEMPTS=`expr ${ATTEMPTS} + 1`
  else
    echo "Network not configured, OD binding failed (${MAX_ATTEMPTS} attempts), will retry at next boot!" 2>&1
    exit 1
  fi
done

#
# Wait for the related server to be reachable
#
SUCCESS=
is_ip_address "${ODM_SERVER}"
if [ ${?} -eq 0 ]
then
  # the ODM_SERVER variable contains an IP address, let's try to ping the server
  echo "Testing ${ODM_SERVER} reachability on address ${ODM_SERVER}" 2>&1  
  if ping -t 5 -c 1 "${ODM_SERVER}" | grep "round-trip"
  then
    echo "Ping successful!" 2>&1
    SUCCESS="YES"
  else
    echo "Ping failed..." 2>&1
  fi
else
  ATTEMPTS=0
  MAX_ATTEMPTS=12
  while [ -z "${SUCCESS}" ]
  do
    if [ ${ATTEMPTS} -lt ${MAX_ATTEMPTS} ]
    then
      ODM_IPS=( `host "${ODM_SERVER}" | grep " has address " | cut -f 4 -d " "` )
      for ODM_IP in ${ODM_IPS[@]}
      do
        echo "Testing ${ODM_SERVER} reachability on address ${ODM_IP}" 2>&1  
        if ping -t 5 -c 1 "${ODM_IP}" | grep "round-trip"
        then
          echo "Ping successful!" 2>&1
          SUCCESS="YES"
        else
          echo "Ping failed..." 2>&1
        fi
        if [ "${SUCCESS}" = "YES" ]
        then
          break
        fi
      done
      if [ -z "${SUCCESS}" ]
      then
        echo "An error occurred while trying to get ${ODM_SERVER} IP addresses, new attempt in 10 seconds..." 2>&1
        sleep 10
        ATTEMPTS=`expr ${ATTEMPTS} + 1`
      fi
    else
      echo "Cannot get any IP address for ${ODM_SERVER} (${MAX_ATTEMPTS} attempts), aborting lookup..." 2>&1
      break
    fi
  done
fi

if [ -z "${SUCCESS}" ]
then
  echo "Cannot reach any IP address of the server ${ODM_SERVER}." 2>&1
  echo "OD binding failed, will retry at next boot!" 2>&1
  exit 1
fi

#
# Enable the LDAPv3 Directory Plugin
#
echo "Enabling the LDAPv3 Plugin" 2>&1
defaults write /Library/Preferences/DirectoryService/DirectoryService "LDAPv3" Active 2>&1
chmod 600 /Library/Preferences/DirectoryService/DirectoryService.plist 2>&1

#
# Unbinding computer
#
#echo "Remove existing local binding config..." 2>&1
#dsconfigldap ${DSCONFIG_OPTIONS} -f -r "${ODM_SERVER}" 2>&1
echo "Unbinding computer..." 2>&1
if [ -n "${COMPUTER_ID}" ] && [ -n "${ADMIN_LOGIN}" ] && [ -n "${ADMIN_PWD}" ]
then
  dsconfigldap ${DSCONFIG_OPTIONS} -f -r "${ODM_SERVER}" -c "${COMPUTER_ID}" -u "${ADMIN_LOGIN}" -p "${ADMIN_PWD}" >/dev/null 2>&1
  if [ ${?} -ne 0 ]
  then
    dsconfigldap ${DSCONFIG_OPTIONS} -f -r "${ODM_SERVER}" >/dev/null  2>&1
  fi
else
  dsconfigldap ${DSCONFIG_OPTIONS} -f -r "${ODM_SERVER}" >/dev/null 2>&1
fi

#
# Try to bind the computer
#
echo "Binding computer..." 2>&1

ATTEMPTS=0
MAX_ATTEMPTS=12
SUCCESS=
while [ -z "${SUCCESS}" ]
do
  if [ ${ATTEMPTS} -lt ${MAX_ATTEMPTS} ]
  then
    if [ -n "${ENABLE_TRUSTED_BINDING}" ] && [ "${ENABLE_TRUSTED_BINDING}" = "YES" ] && [ -n "${COMPUTER_ID}" ] && [ -n "${ADMIN_LOGIN}" ] && [ -n "${ADMIN_PWD}" ]
    then
      TRUST_INFORMATION="Authenticated"
      dsconfigldap ${DSCONFIG_OPTIONS} -f -a "${ODM_SERVER}" -c "${COMPUTER_ID}" -u "${ADMIN_LOGIN}" -p "${ADMIN_PWD}" 2>&1
      if [ ${?} -eq 0 ]
      then
        SUCCESS="YES"
      else
        echo "An error occurred while trying to establish a trusted binding with the server ${ODM_SERVER}, new attempt in 10 seconds..." 2>&1
        sleep 10
        ATTEMPTS=`expr ${ATTEMPTS} + 1`
      fi
    else
      TRUST_INFORMATION="Anonymous"
      dsconfigldap ${DSCONFIG_OPTIONS} -a "${ODM_SERVER}" 2>&1 
      if [ ${?} -eq 0 ]
      then
        SUCCESS="YES"
      else
        echo "An error occurred while trying to establish an anonymous binding with the server ${ODM_SERVER}, new attempt in 10 seconds..." 2>&1
        sleep 10
        ATTEMPTS=`expr ${ATTEMPTS} + 1`
      fi
    fi
  else
    echo "OD binding failed (${MAX_ATTEMPTS} attempts), will retry at next boot!" 2>&1
    SUCCESS="NO"
  fi
done

if [ "${SUCCESS}" = "YES" ]
then
  #
  # Restart directory services
  #
  echo "Killing DirectoryService daemon..." 2>&1
  killall DirectoryService
  sleep 5

  #
  # Trigger the node availability
  #
  echo "Triggering /LDAPv3/${ODM_SERVER} node..." 2>&1
  NODE_AVAILABILITY=`dscl localhost -read "/LDAPv3/${ODM_SERVER}" | grep "TrustInformation:" | grep "${TRUST_INFORMATION}"`
  ATTEMPTS=0
  MAX_ATTEMPTS=12
  while [ -z "${NODE_AVAILABILITY}" ]
  do
    if [ ${ATTEMPTS} -le ${MAX_ATTEMPTS} ]
    then
      NODE_AVAILABILITY=`dscl localhost -read "/LDAPv3/${ODM_SERVER}" | grep "TrustInformation:" | grep "${TRUST_INFORMATION}"`
      if [ -z "${NODE_AVAILABILITY}" ]
      then
        echo "The /LDAPv3/${ODM_SERVER} node is unavailable, new attempt in 10 seconds..." 2>&1
        sleep 10
        ATTEMPTS=`expr ${ATTEMPTS} + 1`
      fi
    else
      echo "OD directory node lookup failed (${MAX_ATTEMPTS} attempts), will retry at next boot!" 2>&1
      exit 1
    fi
  done

  #
  # Update the search policy
  #
  echo "Updating authentication search policy..." 2>&1
  CSP_SEARCH_POLICY=`dscl localhost -read /Search | grep "SearchPolicy:" | grep -i 'CSPSearchPath'`
  if [ -z "${CSP_SEARCH_POLICY}" ]
  then
    ATTEMPTS=0
    MAX_ATTEMPTS=12
    SUCCESS=
    while [ -z "${SUCCESS}" ]
    do
      if [ ${ATTEMPTS} -le ${MAX_ATTEMPTS} ]
      then
        dscl localhost -create /Search SearchPolicy CSPSearchPath 2>&1
        if [ ${?} -eq 0 ]
        then
          SUCCESS="YES"
        else
          echo "An error occured while trying to update the authentication search policy, new attempt in 10 seconds..." 2>&1
          sleep 10
          ATTEMPTS=`expr ${ATTEMPTS} + 1`
        fi
      else
        echo "Authentication search policy update failed (${MAX_ATTEMPTS} attempts), will retry at next boot!" 2>&1
        exit 1
      fi
    done
  fi

  echo "Updating contacts search policy..." 2>&1
  CSP_SEARCH_POLICY=`dscl localhost -read /Contact | grep "SearchPolicy:" | grep -i 'CSPSearchPath'`
  if [ -z "${CSP_SEARCH_POLICY}" ]
  then
    ATTEMPTS=0
    MAX_ATTEMPTS=12
    SUCCESS=
    while [ -z "${SUCCESS}" ]
    do
      if [ ${ATTEMPTS} -le ${MAX_ATTEMPTS} ]
      then
        dscl localhost -create /Contact SearchPolicy CSPSearchPath 2>&1
        if [ ${?} -eq 0 ]
        then
          SUCCESS="YES"
        else
          echo "An error occured while trying to update the contacts search policy, new attempt in 10 seconds..." 2>&1
          sleep 10
          ATTEMPTS=`expr ${ATTEMPTS} + 1`
        fi
      else
        echo "Contacts search policy update failed (${MAX_ATTEMPTS} attempts), will retry at next boot!" 2>&1
        exit 1
      fi
    done
  fi
  
  #
  # Add the OD server to the search path
  #
  echo "Updating authentication search path..." 2>&1
  OD_SEARCH_PATH=`dscl localhost -read /Search | grep "CSPSearchPath:" | grep -i "/LDAPv3/${ODM_SERVER}"`
  if [ -z "${OD_SEARCH_PATH}" ]
  then
    ATTEMPTS=0
    MAX_ATTEMPTS=12
    SUCCESS=
    while [ -z "${SUCCESS}" ]
    do
      if [ ${ATTEMPTS} -le ${MAX_ATTEMPTS} ]
      then
        dscl localhost -append /Search CSPSearchPath "/LDAPv3/${ODM_SERVER}" 2>&1
        if [ ${?} -eq 0 ]
        then
          SUCCESS="YES"
        else
          echo "An error occured while trying to update the authentication search path, new attempt in 10 seconds..." 2>&1
          sleep 10
          ATTEMPTS=`expr ${ATTEMPTS} + 1`
        fi
      else
        echo "Authentication search path update failed (${MAX_ATTEMPTS} attempts), will retry at next boot!" 2>&1
        exit 1
      fi
    done
  fi

  echo "Updating contacts search path..." 2>&1
  OD_SEARCH_PATH=`dscl localhost -read /Contact | grep "CSPSearchPath:" | grep -i "/LDAPv3/${ODM_SERVER}"`
  if [ -z "${OD_SEARCH_PATH}" ]
  then
    ATTEMPTS=0
    MAX_ATTEMPTS=12
    SUCCESS=
    while [ -z "${SUCCESS}" ]
    do
      if [ ${ATTEMPTS} -le ${MAX_ATTEMPTS} ]
      then
        dscl localhost -append /Contact CSPSearchPath "/LDAPv3/${ODM_SERVER}" 2>&1
        if [ ${?} -eq 0 ]
        then
          SUCCESS="YES"
        else
          echo "An error occured while trying to update the contacts search path, new attempt in 10 seconds..." 2>&1
          sleep 10
          ATTEMPTS=`expr ${ATTEMPTS} + 1`
        fi
      else
        echo "Contacts search path update failed (${MAX_ATTEMPTS} attempts), will retry at next boot!" 2>&1
        exit 1
      fi
    done
  fi

  #
  # Add this computer to the expected Computer groups
  #
  if [ -n "${CM_COMPUTER_GROUPS}" ] && [ -n "${ADMIN_LOGIN}" ] && [ -n "${ADMIN_PWD}" ]
  then
    MAC_ADDR=`ifconfig en0 | grep -w ether | awk '{print $2}'`
    HARDWARE_UUID=`ioreg -rd1 -c IOPlatformExpertDevice | awk -F= '/(UUID)/ { gsub("[ \"]", ""); print $2 }'`

    if [ -n "${ENABLE_TRUSTED_BINDING}" ] && [ "${ENABLE_TRUSTED_BINDING}" = "YES" ]
    then
      COMPUTER_ID="${COMPUTER_ID}\$"
    fi

    # Create/update computer account
    dscl -u "${ADMIN_LOGIN}" -P "${ADMIN_PWD}" /LDAPv3/${ODM_SERVER} -create /Computers/${COMPUTER_ID} ENetAddress  "${MAC_ADDR}"
    dscl -u "${ADMIN_LOGIN}" -P "${ADMIN_PWD}" /LDAPv3/${ODM_SERVER} -merge  /Computers/${COMPUTER_ID} RealName     "${COMPUTER_ID}"   
    dscl -u "${ADMIN_LOGIN}" -P "${ADMIN_PWD}" /LDAPv3/${ODM_SERVER} -merge  /Computers/${COMPUTER_ID} HardwareUUID "${HARDWARE_UUID}"   

    # Get the computer GUID
    COMPUTER_GUID=`dscl /LDAPv3/${ODM_SERVER} -read /Computers/${COMPUTER_ID} | grep GeneratedUID | awk '{ print $2 }'`

    # Loop through computer groups array
    PRIMARY_GROUP_ID=1025
    IFS=","
    for COMPUTER_GROUP in ${CM_COMPUTER_GROUPS}
    do
      # Check if the group exists and try to create it if it doesn't
      INVALID_GROUP=
      dscl /LDAPv3/${ODM_SERVER} -read /ComputerGroups/"${COMPUTER_GROUP}" RecordName >/dev/null 2>&1
      if [ ${?} -ne 0 ]
      then
        RECORD_NAME=`dscl /LDAPv3/${ODM_SERVER} -search /ComputerGroups RealName "${COMPUTER_GROUP}" | head -n 1 | awk '{ print $1 }'`
        if [ -n "${RECORD_NAME}" ]
        then
          COMPUTER_GROUP=${RECORD_NAME}
        else
          if [ -n "${CREATE_COMPUTER_GROUPS}" ] && [ "${CREATE_COMPUTER_GROUPS}" = 'YES' ]
          then
            RECORD_NAME=`echo "${COMPUTER_GROUP}" | tr '[:upper:]' '[:lower:]' | tr -s ' ' '_'`

            DUPLICATE_ID=`dscl /LDAPv3/${ODM_SERVER} -search / PrimaryGroupID ${PRIMARY_GROUP_ID}`
            while [ -n "${DUPLICATE_ID}" ]
            do
              PRIMARY_GROUP_ID=`expr ${PRIMARY_GROUP_ID} + 1`
              DUPLICATE_ID=`dscl /LDAPv3/${ODM_SERVER} -search / PrimaryGroupID ${PRIMARY_GROUP_ID}`
            done

            echo "Creating computer group '${COMPUTER_GROUP}'/'${RECORD_NAME}'..."
            if [ `sw_vers -productVersion | awk -F. '{ print $2 }'` -gt 5 ]
            then
              dseditgroup -o create -n /LDAPv3/${ODM_SERVER} -u "${ADMIN_LOGIN}" -P "${ADMIN_PWD}" -r "${COMPUTER_GROUP}" -i ${PRIMARY_GROUP_ID} -L -T computergroup -q "${RECORD_NAME}"
            else
              dscl -u "${ADMIN_LOGIN}" -P "${ADMIN_PWD}" /LDAPv3/${ODM_SERVER} -create /ComputerGroups/"${RECORD_NAME}" GeneratedUID   `uuidgen`
              dscl -u "${ADMIN_LOGIN}" -P "${ADMIN_PWD}" /LDAPv3/${ODM_SERVER} -merge  /ComputerGroups/"${RECORD_NAME}" PrimaryGroupID "${PRIMARY_GROUP_ID}"
              dscl -u "${ADMIN_LOGIN}" -P "${ADMIN_PWD}" /LDAPv3/${ODM_SERVER} -merge  /ComputerGroups/"${RECORD_NAME}" RealName       "${COMPUTER_GROUP}"
            fi
            if [ ${?} -eq 0 ]
            then
              COMPUTER_GROUP=${RECORD_NAME}
            else
              echo "Failed to create '${COMPUTER_GROUP}'/'${RECORD_NAME}' computer group!"
              INVALID_GROUP="YES"
            fi
          else
            echo "The computer group '${COMPUTER_GROUP}' doesn't exist, skipping!"
            INVALID_GROUP="YES"
          fi
        fi
      fi
      if [ -z "${INVALID_GROUP}" ]
      then
        echo "Adding ${COMPUTER_ID} to computer group '${COMPUTER_GROUP}'..."
        if [ `sw_vers -productVersion | awk -F. '{ print $2 }'` -gt 5 ]
        then
          dseditgroup -o edit -n /LDAPv3/${ODM_SERVER} -u "${ADMIN_LOGIN}" -P "${ADMIN_PWD}" -a "${COMPUTER_ID}" -L -t computer -T computergroup -q "${COMPUTER_GROUP}"
        else
          dscl -u "${ADMIN_LOGIN}" -P "${ADMIN_PWD}" /LDAPv3/${ODM_SERVER} -merge /ComputerGroups/"${COMPUTER_GROUP}" apple-group-memberguid "${COMPUTER_GUID}"
          dscl -u "${ADMIN_LOGIN}" -P "${ADMIN_PWD}" /LDAPv3/${ODM_SERVER} -merge /ComputerGroups/"${COMPUTER_GROUP}" memberUid "${COMPUTER_ID}"
        fi
        if [ ${?} -ne 0 ]
        then
          echo "Failed to add '${COMPUTER_ID}' to '${COMPUTER_GROUP}' computer group!"
        fi
      fi
    done
  fi

  #
  # Self-removal
  #
  if [ "${SUCCESS}" = "YES" ]
  then
    if [ -n "${ADMIN_LOGIN}" ] && [ -n "${ADMIN_PWD}" ] && [ -e "/System/Library/CoreServices/ServerVersion.plist" ]
    then
      DEFAULT_REALM=`more /Library/Preferences/edu.mit.Kerberos | grep default_realm | awk '{ print $3 }'`
      if [ -n "${DEFAULT_REALM}" ]
      then
        echo "The binding process looks good, will try to configure Kerberized services on this machine for the default realm ${DEFAULT_REALM}..." 2>&1
        /usr/sbin/sso_util configure -r "${DEFAULT_REALM}" -a "${ADMIN_LOGIN}" -p "${ADMIN_PWD}" all
      fi
    fi
    if [ -e "${CONFIG_FILE}" ]
    then
      rm -Pf "${CONFIG_FILE}"
    fi
    rm -f "${0}"
    exit 0
  fi
fi

exit 1
