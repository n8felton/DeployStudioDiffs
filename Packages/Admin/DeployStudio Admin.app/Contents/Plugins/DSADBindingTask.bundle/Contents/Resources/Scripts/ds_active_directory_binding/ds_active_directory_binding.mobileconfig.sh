#!/bin/sh

SCRIPT_NAME=`basename "${0}"`

echo "${SCRIPT_NAME} - v1.29 ("`date`")"

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
# Import configuration profile
#
CONFIGURATION_PROFILE=`echo "${0}" | sed s/\.sh$/\.mobileconfig/`
if [ -e "${CONFIGURATION_PROFILE}" ]
then
  echo "Importing the configuration profile '${CONFIGURATION_PROFILE}'"
  profiles -I -F "${CONFIGURATION_PROFILE}"
  if [ ${?} -ne 0 ]
  then
    echo "Configuration profile import failed, will retry on next boot!"
    exit 1
  fi
fi

#
# Self-removal
#
if [ -e "${CONFIGURATION_PROFILE}" ]
then
  rm -Pf "${CONFIGURATION_PROFILE}"
fi
rm -f "${0}"

exit 0