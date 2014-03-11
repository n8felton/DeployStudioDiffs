#!/bin/sh

SCRIPT_NAME=`/usr/bin/basename "${0}"`

echo "${SCRIPT_NAME} - v1.2 ("`date`")"

#
# Set system timezone
#
if [ -n "__TIMEZONE__" ]
then
  if [ "__TIMEZONE__" = "autodetect" ]
  then
    echo "Enabling timezone auto detection..."
    defaults write /Library/Preferences/com.apple.timezone.auto Active -bool YES
  else
    defaults write /Library/Preferences/com.apple.timezone.auto Active -bool NO
    /usr/sbin/systemsetup -settimezone "__TIMEZONE__"
  fi
fi

#
# Set system network time server
#
if [ -n "__NTP_SERVER__" ]
then
  /usr/sbin/systemsetup -setusingnetworktime off
  /usr/sbin/systemsetup -setnetworktimeserver "__NTP_SERVER__"
  /usr/sbin/systemsetup -setusingnetworktime on
fi

#
# Self removal
#
/usr/bin/srm -mf "${0}"

exit 0