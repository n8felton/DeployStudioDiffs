#!/bin/sh

# get machine serial number
MAC_SERIAL_NUMBER=`ioreg -l | grep IOPlatformSerialNumber|awk '{print $4}' | cut -d \" -f 2`

# echo the value prefixed by "RuntimeSetBindingComputerID:" to make it compatible with the directory binding tasks
echo "RuntimeSetBindingComputerID: ${MAC_SERIAL_NUMBER}"

exit 0