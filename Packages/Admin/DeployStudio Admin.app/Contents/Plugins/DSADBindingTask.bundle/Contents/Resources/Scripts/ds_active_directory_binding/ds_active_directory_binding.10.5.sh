#!/bin/sh

# disable history characters
histchars=

SCRIPT_NAME=`basename "${0}"`

echo "${SCRIPT_NAME} - v1.23 ("`date`")"

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
AD_DOMAIN=`/usr/libexec/PlistBuddy -c "Print :domain" "${CONFIG_FILE}" 2>/dev/null`
COMPUTER_ID=`/usr/libexec/PlistBuddy -c "Print :id" "${CONFIG_FILE}" 2>/dev/null`
COMPUTERS_OU=`/usr/libexec/PlistBuddy -c "Print :ou" "${CONFIG_FILE}" 2>/dev/null`
ADMIN_LOGIN=`/usr/libexec/PlistBuddy -c "Print :admin" "${CONFIG_FILE}" 2>/dev/null`
ADMIN_PWD=`/usr/libexec/PlistBuddy -c "Print :password" "${CONFIG_FILE}" 2>/dev/null`

MOBILE=`/usr/libexec/PlistBuddy -c "Print :mobile" "${CONFIG_FILE}" 2>/dev/null`
MOBILE_CONFIRM=`/usr/libexec/PlistBuddy -c "Print :mobileconfirm" "${CONFIG_FILE}" 2>/dev/null`
LOCAL_HOME=`/usr/libexec/PlistBuddy -c "Print :localhome" "${CONFIG_FILE}" 2>/dev/null`
USE_UNC_PATHS=`/usr/libexec/PlistBuddy -c "Print :useuncpath" "${CONFIG_FILE}" 2>/dev/null`
UNC_PATHS_PROTOCOL=`/usr/libexec/PlistBuddy -c "Print :protocol" "${CONFIG_FILE}" 2>/dev/null`
PACKET_SIGN=`/usr/libexec/PlistBuddy -c "Print :packetsign" "${CONFIG_FILE}" 2>/dev/null`
PACKET_ENCRYPT=`/usr/libexec/PlistBuddy -c "Print :packetencrypt" "${CONFIG_FILE}" 2>/dev/null`
PASSWORD_INTERVAL=`/usr/libexec/PlistBuddy -c "Print :passinterval" "${CONFIG_FILE}" 2>/dev/null`
AUTH_DOMAIN=`/usr/libexec/PlistBuddy -c "Print :authdomain" "${CONFIG_FILE}" 2>/dev/null`
ADMIN_GROUPS=`/usr/libexec/PlistBuddy -c "Print :admingroups" "${CONFIG_FILE}" 2>/dev/null`

UID_MAPPING=`/usr/libexec/PlistBuddy -c "Print :uid" "${CONFIG_FILE}" 2>/dev/null`
GID_MAPPING=`/usr/libexec/PlistBuddy -c "Print :gid" "${CONFIG_FILE}" 2>/dev/null`
GGID_MAPPING=`/usr/libexec/PlistBuddy -c "Print :ggid" "${CONFIG_FILE}" 2>/dev/null`

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
    echo "Network not configured, AD binding failed (${MAX_ATTEMPTS} attempts), will retry at next boot!" 2>&1
	exit 1
  fi
done

#
# Wait for the related server to be reachable
# NB: AD service entries must be correctly set in DNS
#
SUCCESS=
is_ip_address "${AD_DOMAIN}"
if [ ${?} -eq 0 ]
then
  # the AD_DOMAIN variable contains an IP address, let's try to ping the server
  echo "Testing ${AD_DOMAIN} reachability on address ${ODM_SERVER}" 2>&1  
  if ping -t 5 -c 1 "${AD_DOMAIN}" | grep "round-trip"
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
      AD_DOMAIN_IPS=( `host "${AD_DOMAIN}" | grep " has address " | cut -f 4 -d " "` )
      for AD_DOMAIN_IP in ${AD_DOMAIN_IPS[@]}
      do
        echo "Testing ${AD_DOMAIN} reachability on address ${AD_DOMAIN_IP}" 2>&1  
        if ping -t 5 -c 1 ${AD_DOMAIN_IP} | grep "round-trip"
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
        echo "An error occurred while trying to get ${AD_DOMAIN} IP addresses, new attempt in 10 seconds..." 2>&1
        sleep 10
        ATTEMPTS=`expr ${ATTEMPTS} + 1`
      fi
    else
      echo "Cannot get any IP address for ${AD_DOMAIN} (${MAX_ATTEMPTS} attempts), aborting lookup..." 2>&1
      break
    fi
  done
fi

if [ -z "${SUCCESS}" ]
then
  echo "Cannot reach any IP address of the domain ${AD_DOMAIN}." 2>&1
  echo "AD binding failed, will retry at next boot!" 2>&1
  exit 1
fi

#
# Enable the Active Directory Plugin first
#
echo "Enabling the Active Directory Plugin" 2>&1
defaults write /Library/Preferences/DirectoryService/DirectoryService "Active Directory" Active 2>&1
chmod 600 /Library/Preferences/DirectoryService/DirectoryService.plist 2>&1

#
# Unbinding computer first
#
echo "Unbinding computer..." 2>&1
dsconfigad -f -r -u "${ADMIN_LOGIN}" -p "${ADMIN_PWD}" -status 2>&1

#
# Set pre-binding options
#
echo "Setting AD plugin options before binding..." 2>&1
dsconfigad -mobile ${MOBILE} -mobileconfirm ${MOBILE_CONFIRM} -localhome ${LOCAL_HOME} -useuncpath ${USE_UNC_PATHS} -protocol ${UNC_PATHS_PROTOCOL} -status 2>&1
if [ `sw_vers -productVersion | awk -F. '{ print $2 }'` -ge 5 ]
then
  dsconfigad -packetsign ${PACKET_SIGN} -packetencrypt ${PACKET_ENCRYPT} -passinterval ${PASSWORD_INTERVAL} -status 2>&1
fi
if [ -n "${ADMIN_GROUPS}" ]
then
  dsconfigad -groups "${ADMIN_GROUPS}" -status 2>&1
fi
if [ "${AUTH_DOMAIN}" != 'All Domains' ]
then
  dsconfigad -alldomains disable -status 2>&1
fi
if [ -n "${UID_MAPPING}" ]
then
  dsconfigad -uid "${UID_MAPPING}" -status 2>&1
fi
if [ -n "${GID_MAPPING}" ]
then
  dsconfigad -gid "${GID_MAPPING}" -status 2>&1
fi
if [ -n "${GGID_MAPPING}" ]
then
  dsconfigad -ggid "${GGID_MAPPING}" -status 2>&1
fi

#
# Try to bind the computer
#
ATTEMPTS=0
MAX_ATTEMPTS=12
SUCCESS=
while [ -z "${SUCCESS}" ]
do
  if [ ${ATTEMPTS} -le ${MAX_ATTEMPTS} ]
  then
    echo "Binding computer to domain ${AD_DOMAIN}..." 2>&1
    dsconfigad -f -a "${COMPUTER_ID}" -domain "${AD_DOMAIN}" -ou "${COMPUTERS_OU}" -u "${ADMIN_LOGIN}" -p "${ADMIN_PWD}" -status 2>&1
	IS_BOUND=`defaults read /Library/Preferences/DirectoryService/ActiveDirectory "AD Bound to Domain"`
    if [ ${IS_BOUND} -eq 1 ]
    then
	  SUCCESS="YES"
    else
	  echo "An error occured while trying to bind this computer to AD, new attempt in 10 seconds..." 2>&1
      sleep 10
      ATTEMPTS=`expr ${ATTEMPTS} + 1`
    fi
  else
    echo "AD binding failed (${MAX_ATTEMPTS} attempts), will retry at next boot!" 2>&1
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
  echo "Triggering '/Active Directory/${AUTH_DOMAIN}' node..." 2>&1
  NODE_AVAILABILITY=`dscl localhost -read "/Active Directory/${AUTH_DOMAIN}" | grep "NodeAvailability:" | grep "Available"`
  ATTEMPTS=0
  MAX_ATTEMPTS=12
  while [ -z "${NODE_AVAILABILITY}" ]
  do
    if [ ${ATTEMPTS} -le ${MAX_ATTEMPTS} ]
    then
      NODE_AVAILABILITY=`dscl localhost -read "/Active Directory/${AUTH_DOMAIN}" | grep "NodeAvailability:" | grep "Available"`
	  if [ -z "${NODE_AVAILABILITY}" ]
	  then
	    echo "The '/Active Directory/${AUTH_DOMAIN}' node is unavailable, new attempt in 10 seconds..." 2>&1
        sleep 10
        ATTEMPTS=`expr ${ATTEMPTS} + 1`
      fi
    else
      echo "AD directory node lookup failed (${MAX_ATTEMPTS} attempts), will retry at next boot!" 2>&1
      exit 1
    fi
  done

  #
  # Update the search policy
  #
  echo "Updating authentication search policy..." 2>&1
  CSP_SEARCH_POLICY=`dscl localhost -read /Search | grep "SearchPolicy:" | grep -i "CSPSearchPath"`
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
  CSP_SEARCH_POLICY=`dscl localhost -read /Contact | grep "SearchPolicy:" | grep -i "CSPSearchPath"`
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
  # Add "${AUTH_DOMAIN}" to the search path
  #
  echo "Updating authentication search path..." 2>&1
  AD_SEARCH_PATH=`dscl localhost -read /Search | grep "CSPSearchPath:" | grep -i "/Active Directory/${AUTH_DOMAIN}"`
  if [ -z "${AD_SEARCH_PATH}" ]
  then
    ATTEMPTS=0
    MAX_ATTEMPTS=12
    SUCCESS=
    while [ -z "${SUCCESS}" ]
    do
      if [ ${ATTEMPTS} -le ${MAX_ATTEMPTS} ]
      then
        dscl localhost -append /Search CSPSearchPath "/Active Directory/${AUTH_DOMAIN}" 2>&1
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
  AD_SEARCH_PATH=`dscl localhost -read /Contact | grep "CSPSearchPath:" | grep -i "/Active Directory/${AUTH_DOMAIN}"`
  if [ -z "${AD_SEARCH_PATH}" ]
  then
    ATTEMPTS=0
    MAX_ATTEMPTS=12
    SUCCESS=
    while [ -z "${SUCCESS}" ]
    do
      if [ ${ATTEMPTS} -le ${MAX_ATTEMPTS} ]
      then
        dscl localhost -append /Contact CSPSearchPath "/Active Directory/${AUTH_DOMAIN}" 2>&1
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
  # Self-removal
  #
  if [ "${SUCCESS}" = "YES" ]
  then
    if [ -e "/System/Library/CoreServices/ServerVersion.plist" ]
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
