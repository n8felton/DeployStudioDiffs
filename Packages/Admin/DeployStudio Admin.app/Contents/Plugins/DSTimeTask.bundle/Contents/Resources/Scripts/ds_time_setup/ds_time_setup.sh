#!/bin/sh

SCRIPT_NAME=`/usr/bin/basename "${0}"`

echo "${SCRIPT_NAME} - v1.4 ("`date`")"

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

    GLOBAL_PREFS="/Library/Preferences/.GlobalPreferences.plist"
    SELECTED_CITY="com.apple.preferences.timezone.selected_city"

    ATTEMPTS=0
    MAX_ATTEMPTS=6

    SELECTED_CITY_DEFINED=`defaults read "${GLOBAL_PREFS}" ${SELECTED_CITY} 2>/dev/null`

    while [ -z "${SELECTED_CITY_DEFINED}" ] && [ ${ATTEMPTS} -le ${MAX_ATTEMPTS} ]
    do
      echo "Waiting for timezone to be configured..." 2>&1
      sleep 5
      ATTEMPTS=`expr ${ATTEMPTS} + 1`
      SELECTED_CITY_DEFINED=`defaults read "${GLOBAL_PREFS}" ${SELECTED_CITY} 2>/dev/null`
    done

    if [ -z "${SELECTED_CITY_DEFINED}" ]
    then
      echo "Selected city not set, macOS setup assistant might display the wrong timezone..." 2>&1
    fi

#    if [ -z "${SELECTED_CITY_DEFINED}" ]
#    then
#      PlistBuddy="/usr/libexec/PlistBuddy"

#      "${PlistBuddy}" -c "Add :${SELECTED_CITY} dict" "${GLOBAL_PREFS}"
##     "${PlistBuddy}" -c "Add :${SELECTED_CITY}:AppleMapID integer 144136152979344160" "${GLOBAL_PREFS}"
#      "${PlistBuddy}" -c "Add :${SELECTED_CITY}:CountryCode string __COUNTRY_CODE__" "${GLOBAL_PREFS}"
#      "${PlistBuddy}" -c "Add :${SELECTED_CITY}:Latitude real __LATITUDE__" "${GLOBAL_PREFS}"
#      "${PlistBuddy}" -c "Add :${SELECTED_CITY}:Longitude real __LONGITUDE__" "${GLOBAL_PREFS}"
#      "${PlistBuddy}" -c "Add :${SELECTED_CITY}:LocalizedNames dict" "${GLOBAL_PREFS}"
#      "${PlistBuddy}" -c "Add :${SELECTED_CITY}:LocalizedNames:en string '__CITY_NAME__'" "${GLOBAL_PREFS}"
#      "${PlistBuddy}" -c "Add :${SELECTED_CITY}:Name string '__CITY_NAME__'" "${GLOBAL_PREFS}"
##     "${PlistBuddy}" -c "Add :${SELECTED_CITY}:Population integer 7825200" "${GLOBAL_PREFS}"
#      "${PlistBuddy}" -c "Add :${SELECTED_CITY}:TimeZoneName string __TIMEZONE__" "${GLOBAL_PREFS}"
#      "${PlistBuddy}" -c "Add :${SELECTED_CITY}:Version integer 1" "${GLOBAL_PREFS}"
#    fi
  fi
fi

#
# Set system network time server
#
if [ -n "__NTP_SERVER__" ]
then
  touch /etc/ntp.conf
  /usr/sbin/systemsetup -setnetworktimeserver "__NTP_SERVER__"
  /usr/sbin/systemsetup -setusingnetworktime on
fi

#
# Self removal
#
rm -f "${0}"

exit 0
