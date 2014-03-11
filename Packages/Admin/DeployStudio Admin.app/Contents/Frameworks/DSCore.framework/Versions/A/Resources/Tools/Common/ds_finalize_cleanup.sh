#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
SCRIPT_PATH=`dirname "${0}"`

/bin/echo "${SCRIPT_NAME} - v1.0 ("`date`")"

custom_logger() {
  /bin/echo "${SCRIPT_NAME} - $1"
}

# launchd configuration files removal
custom_logger "removing launchd configuration files"

if [ -e /Library/LaunchDaemons/com.deploystudio.finalizeScript.plist ]
then
  /usr/bin/srm -mf /Library/LaunchDaemons/com.deploystudio.finalizeScript.plist 2>/dev/null
else
  /usr/bin/srm -mf /Library/LaunchAgents/com.deploystudio.finalizeScript.plist  2>/dev/null
  /usr/bin/srm -mf /Library/LaunchAgents/com.deploystudio.FinalizeApp.plist     2>/dev/null
fi
/usr/bin/srm -mf /Library/LaunchDaemons/com.deploystudio.finalizeCleanup.plist 2>/dev/null

custom_logger "end"

# Self-removal
/usr/bin/srm -rmf /etc/deploystudio

exit 0