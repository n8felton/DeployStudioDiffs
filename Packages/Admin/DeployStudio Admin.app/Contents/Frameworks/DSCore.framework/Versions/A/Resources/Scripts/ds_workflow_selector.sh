#!/bin/sh

# get machine model
MACHINE_MODEL=`/usr/sbin/ioreg -c IOPlatformExpertDevice | grep "model" | awk -F\" '{ print $4 }'`

# echo the workflow ID or title prefixed by "RuntimeSelectWorkflow:" according to the machine model
if [ "${MACHINE_MODEL}" == "MacBookAir3,2" ]
then
  echo "RuntimeSelectWorkflow: 040622200000"
  #echo "RuntimeSelectWorkflow: Create a master"
fi

exit 0
