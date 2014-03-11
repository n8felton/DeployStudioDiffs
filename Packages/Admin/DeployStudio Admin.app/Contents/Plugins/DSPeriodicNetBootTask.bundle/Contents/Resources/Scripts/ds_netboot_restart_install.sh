#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
SCRIPT_PATH=`dirname "${0}"`

PLBUDDY=/usr/libexec/PlistBuddy

echo "${SCRIPT_NAME} - v1.13 ("`date`")"

if [ ${#} -lt 5 ]
then
  echo "Command: ${SCRIPT_NAME} ${*}"
  echo "Usage: ${SCRIPT_NAME} <volume name> <timezone in minutes from GMT> <hour> <minute> <mode> [<day>] [netboot server [nbi folder name]] [-force]"
  echo "       <mode> = d | w | m (daily, weekly, monthly)"
  echo "RuntimeAbortWorkflow: missing arguments!"
  exit 1
fi

if [ "_${6}" = "_-force" ] || [ "_${7}" = "_-force" ] || [ "_${8}" = "_-force" ] || [ "_${9}" = "_-force" ]
then
  FORCE="\<string\>-force\<\/string\>"
fi

if [ "${1}" = "/" ]
then
  VOLUME_PATH=/
else
  VOLUME_PATH=/Volumes/${1}
fi

if [ ! -e "${VOLUME_PATH}" ]
then
  echo "Command: ${SCRIPT_NAME} ${*}"
  echo "Usage: ${SCRIPT_NAME} <volume name> <timezone in minutes from GMT> <hour> <minute> <mode> [<day>] [-force]"
  echo "       <mode> = d | w | m (daily, weekly, monthly)"
  echo "RuntimeAbortWorkflow: \"${VOLUME_PATH}\" volume not found!"
  exit 1
fi

if [ ! -e "${VOLUME_PATH}"/Library/Preferences/SystemConfiguration ]
then
  mkdir -p "${VOLUME_PATH}"/Library/Preferences/SystemConfiguration
  chmod 775 "${VOLUME_PATH}"/Library/Preferences
  chown root:admin "${VOLUME_PATH}"/Library/Preferences
  chmod 755 "${VOLUME_PATH}"/Library/Preferences/SystemConfiguration
  chown root:admin "${VOLUME_PATH}"/Library/Preferences/SystemConfiguration
fi

TIMEZONE=${2}
HOUR=${3}
MINUTE=${4}
MODE=${5}

if [ "_${MODE}" = "_w" ] || [ "_${MODE}" = "_m" ]
then
  DAY=${6}
  NETBOOT_SERVER_IP=${7}
  NETBOOT_SET_FOLDER_NAME=${8}
else
  NETBOOT_SERVER_IP=${6}
  NETBOOT_SET_FOLDER_NAME=${7}
fi

# the boot delay (minutes) is substracted from the netboot scheduled time in 
# order to save time to start a turned off computer. 
BOOT_DELAY=10

if [ "_${MODE}" != "_d" ]
then
  if [ "_${DAY}" = "_" ]
  then
    echo "RuntimeAbortWorkflow: missing day argument for mode ${MODE}!"
  	echo "Usage: ${SCRIPT_NAME} <volume name> <timezone in minutes from GMT> <hour> <minute> <mode> [<day>] [-force]"
  	echo "       <mode> = d | w | m (daily, weekly, monthly)"
    exit 1
  fi
fi

if [ "_${MODE}" = "_d" ]
then
  if [ -e "${VOLUME_PATH}"/System/Library/LaunchDaemons ]
  then
    echo "configuring launchd to netboot the computer at ${HOUR}:${MINUTE} every day"
    cp "${SCRIPT_PATH}"/ds_netboot_restart/com.deploystudio.netboot_restart_daily.plist \
       "${VOLUME_PATH}"/Library/LaunchDaemons/com.deploystudio.netboot_restart.plist

    ${PLBUDDY} -c "Delete :StartCalendarInterval" "${VOLUME_PATH}"/Library/LaunchDaemons/com.deploystudio.netboot_restart.plist &>/dev/null
    ${PLBUDDY} -c "Add :StartCalendarInterval dict" "${VOLUME_PATH}"/Library/LaunchDaemons/com.deploystudio.netboot_restart.plist
    ${PLBUDDY} -c "Add :StartCalendarInterval:Hour integer '${HOUR}'" "${VOLUME_PATH}"/Library/LaunchDaemons/com.deploystudio.netboot_restart.plist
    ${PLBUDDY} -c "Add :StartCalendarInterval:Minute integer '${MINUTE}'" "${VOLUME_PATH}"/Library/LaunchDaemons/com.deploystudio.netboot_restart.plist

    if [ -n "${NETBOOT_SERVER_IP}" ]
    then
      ${PLBUDDY} -c "Add :ProgramArguments: string '-server=${NETBOOT_SERVER_IP}'" "${VOLUME_PATH}"/Library/LaunchDaemons/com.deploystudio.netboot_restart.plist
    fi

    if [ -n "${NETBOOT_SET_FOLDER_NAME}" ]
    then
      ${PLBUDDY} -c "Add :ProgramArguments: string '-nbi=${NETBOOT_SET_FOLDER_NAME}'" "${VOLUME_PATH}"/Library/LaunchDaemons/com.deploystudio.netboot_restart.plist
    fi

    if [ -n "${FORCE}" ]
    then
      ${PLBUDDY} -c "Add :ProgramArguments: string '-force'" "${VOLUME_PATH}"/Library/LaunchDaemons/com.deploystudio.netboot_restart.plist
    fi

    chmod 644 "${VOLUME_PATH}"/Library/LaunchDaemons/com.deploystudio.netboot_restart.plist
	chown root:wheel "${VOLUME_PATH}"/Library/LaunchDaemons/com.deploystudio.netboot_restart.plist
  else
    echo "configuring crontab to netboot the computer at ${HOUR}:${MINUTE} every day"
    printf "\n${MINUTE}\t${HOUR}\t*\t*\t*\troot\t/usr/local/sbin/ds_netboot_restart.sh" >> "${VOLUME_PATH}"/etc/crontab
    sed '/^[[:space:]]*$/d' "${VOLUME_PATH}"/etc/crontab > "${VOLUME_PATH}"/etc/crontab2
    mv -f "${VOLUME_PATH}"/etc/crontab2 "${VOLUME_PATH}"/etc/crontab
  fi

  echo "creating com.apple.AutoWake.plist preference file"
  PREFS_TIME=`expr ${HOUR} \* 60 + ${MINUTE}`
  PREFS_TIME=`expr ${HOUR} \* 60 + ${MINUTE} - ${BOOT_DELAY}`
  if [ ${PREFS_TIME} -lt 0 ]
  then
    PREFS_TIME=`expr 24 \* 60 + ${MINUTE} - ${BOOT_DELAY}`
  fi
  PREFS_HOUR=`expr \( ${PREFS_TIME} - ${TIMEZONE} \) / 60`
  PREFS_MINUTE=`expr \( ${PREFS_TIME} - ${TIMEZONE} \) % 60`
  if [ ${PREFS_HOUR} -lt 10 ]
  then
	PREFS_HOUR="0"${PREFS_HOUR}
  fi
  if [ ${PREFS_MINUTE} -lt 10 ]
  then
	PREFS_MINUTE="0"${PREFS_MINUTE}
  fi
  PREFS_DAY=127
  PREFS_DATE="2001-01-01"
  sed -e s/__TIME_IN_MINUTES__/${PREFS_TIME}/g \
      -e s/__DAY__/${PREFS_DAY}/g \
      -e s/__DATE__/${PREFS_DATE}/g \
      -e s/__HOUR__/${PREFS_HOUR}/g \
      -e s/__MINUTE__/${PREFS_MINUTE}/g \
      "${SCRIPT_PATH}"/ds_netboot_restart/ds_com.apple.AutoWake.plist > "${VOLUME_PATH}"/Library/Preferences/SystemConfiguration/com.apple.AutoWake.plist
fi

if [ "_${MODE}" = "_w" ]
then
  if [ -e "${VOLUME_PATH}"/System/Library/LaunchDaemons ]
  then
    echo "configuring launchd to netboot the computer at ${HOUR}:${MINUTE} every week on day ${DAY}"
    cp "${SCRIPT_PATH}"/ds_netboot_restart/com.deploystudio.netboot_restart_weekly.plist \
       "${VOLUME_PATH}"/Library/LaunchDaemons/com.deploystudio.netboot_restart.plist

    ${PLBUDDY} -c "Delete :StartCalendarInterval" "${VOLUME_PATH}"/Library/LaunchDaemons/com.deploystudio.netboot_restart.plist &>/dev/null
    ${PLBUDDY} -c "Add :StartCalendarInterval dict" "${VOLUME_PATH}"/Library/LaunchDaemons/com.deploystudio.netboot_restart.plist
    ${PLBUDDY} -c "Add :StartCalendarInterval:Hour integer '${HOUR}'" "${VOLUME_PATH}"/Library/LaunchDaemons/com.deploystudio.netboot_restart.plist
    ${PLBUDDY} -c "Add :StartCalendarInterval:Minute integer '${MINUTE}'" "${VOLUME_PATH}"/Library/LaunchDaemons/com.deploystudio.netboot_restart.plist
    ${PLBUDDY} -c "Add :StartCalendarInterval:Weekday integer '${DAY}'" "${VOLUME_PATH}"/Library/LaunchDaemons/com.deploystudio.netboot_restart.plist

    if [ -n "${NETBOOT_SERVER_IP}" ]
    then
      ${PLBUDDY} -c "Add :ProgramArguments: string '-server=${NETBOOT_SERVER_IP}'" "${VOLUME_PATH}"/Library/LaunchDaemons/com.deploystudio.netboot_restart.plist
    fi

    if [ -n "${NETBOOT_SET_FOLDER_NAME}" ]
    then
      ${PLBUDDY} -c "Add :ProgramArguments: string '-nbi=${NETBOOT_SET_FOLDER_NAME}'" "${VOLUME_PATH}"/Library/LaunchDaemons/com.deploystudio.netboot_restart.plist
    fi

    if [ -n "${FORCE}" ]
    then
      ${PLBUDDY} -c "Add :ProgramArguments: string '-force'" "${VOLUME_PATH}"/Library/LaunchDaemons/com.deploystudio.netboot_restart.plist
    fi

	chmod 644 "${VOLUME_PATH}"/Library/LaunchDaemons/com.deploystudio.netboot_restart.plist
	chown root:wheel "${VOLUME_PATH}"/Library/LaunchDaemons/com.deploystudio.netboot_restart.plist
  else
    echo "configuring crontab to netboot the computer at ${HOUR}:${MINUTE} every week on ${DAY}"
    printf "\n${MINUTE}\t${HOUR}\t*\t*\t${DAY}\troot\t/usr/local/sbin/ds_netboot_restart.sh" >> "${VOLUME_PATH}"/etc/crontab
    sed '/^[[:space:]]*$/d' "${VOLUME_PATH}"/etc/crontab > "${VOLUME_PATH}"/etc/crontab2
    mv -f "${VOLUME_PATH}"/etc/crontab2 "${VOLUME_PATH}"/etc/crontab
  fi
  
  echo "creating com.apple.AutoWake.plist preference file"
  PREFS_TIME=`expr ${HOUR} \* 60 + ${MINUTE}`
  PREFS_TIME=`expr ${HOUR} \* 60 + ${MINUTE} - ${BOOT_DELAY}`
  if [ ${PREFS_TIME} -lt 0 ]
  then
    PREFS_TIME=`expr 24 \* 60 + ${MINUTE} - ${BOOT_DELAY}`
	DAY=`expr ${DAY} - 1`
    if [ ${DAY} -lt 0 ]
	then
	  DAY=6
	fi
  fi
  PREFS_HOUR=`expr \( ${PREFS_TIME} - ${TIMEZONE} \) / 60`
  PREFS_MINUTE=`expr \( ${PREFS_TIME} - ${TIMEZONE} \) % 60`
  if [ ${PREFS_HOUR} -lt 10 ]
  then
	PREFS_HOUR="0"${PREFS_HOUR}
  fi
  if [ ${PREFS_MINUTE} -lt 10 ]
  then
	PREFS_MINUTE="0"${PREFS_MINUTE}
  fi
  if [ ${DAY} -eq 0 ]
  then
    PREFS_DAY=64
  else
    PREFS_DAY=`echo "2 ^ ( ${DAY} - 1 )" | bc`
  fi
  PREFS_DATE="2001-01-0${DAY}"
  sed -e s/__TIME_IN_MINUTES__/${PREFS_TIME}/g \
	  -e s/__DAY__/${PREFS_DAY}/g \
	  -e s/__DATE__/${PREFS_DATE}/g \
	  -e s/__HOUR__/${PREFS_HOUR}/g \
	  -e s/__MINUTE__/${PREFS_MINUTE}/g \
	  "${SCRIPT_PATH}"/ds_netboot_restart/ds_com.apple.AutoWake.plist > "${VOLUME_PATH}"/Library/Preferences/SystemConfiguration/com.apple.AutoWake.plist
fi

if [ "_${MODE}" = "_m" ]
then
  if [ -e "${VOLUME_PATH}"/Library/LaunchDaemons ]
  then
    echo "configuring launchd to netboot the computer at ${HOUR}:${MINUTE} every month on day ${DAY}"
    cp "${SCRIPT_PATH}"/ds_netboot_restart/com.deploystudio.netboot_restart_monthly.plist \
       "${VOLUME_PATH}"/Library/LaunchDaemons/com.deploystudio.netboot_restart.plist

    ${PLBUDDY} -c "Delete :StartCalendarInterval" "${VOLUME_PATH}"/Library/LaunchDaemons/com.deploystudio.netboot_restart.plist &>/dev/null
    ${PLBUDDY} -c "Add :StartCalendarInterval dict" "${VOLUME_PATH}"/Library/LaunchDaemons/com.deploystudio.netboot_restart.plist
    ${PLBUDDY} -c "Add :StartCalendarInterval:Hour integer '${HOUR}'" "${VOLUME_PATH}"/Library/LaunchDaemons/com.deploystudio.netboot_restart.plist
    ${PLBUDDY} -c "Add :StartCalendarInterval:Minute integer '${MINUTE}'" "${VOLUME_PATH}"/Library/LaunchDaemons/com.deploystudio.netboot_restart.plist
    ${PLBUDDY} -c "Add :StartCalendarInterval:Day integer '${DAY}'" "${VOLUME_PATH}"/Library/LaunchDaemons/com.deploystudio.netboot_restart.plist

    if [ -n "${NETBOOT_SERVER_IP}" ]
    then
      ${PLBUDDY} -c "Add :ProgramArguments: string '-server=${NETBOOT_SERVER_IP}'" "${VOLUME_PATH}"/Library/LaunchDaemons/com.deploystudio.netboot_restart.plist
    fi

    if [ -n "${NETBOOT_SET_FOLDER_NAME}" ]
    then
      ${PLBUDDY} -c "Add :ProgramArguments: string '-nbi=${NETBOOT_SET_FOLDER_NAME}'" "${VOLUME_PATH}"/Library/LaunchDaemons/com.deploystudio.netboot_restart.plist
    fi

    if [ -n "${FORCE}" ]
    then
      ${PLBUDDY} -c "Add :ProgramArguments: string '-force'" "${VOLUME_PATH}"/Library/LaunchDaemons/com.deploystudio.netboot_restart.plist
    fi

    chmod 644 "${VOLUME_PATH}"/Library/LaunchDaemons/com.deploystudio.netboot_restart.plist
	chown root:wheel "${VOLUME_PATH}"/Library/LaunchDaemons/com.deploystudio.netboot_restart.plist
  else
    echo "configuring crontab to netboot the computer at ${HOUR}:${MINUTE} every month on day ${DAY}"
    printf "\n${MINUTE}\t${HOUR}\t${DAY}\t*\t*\troot\t/usr/local/sbin/ds_netboot_restart.sh" >> "${VOLUME_PATH}"/etc/crontab
    sed '/^[[:space:]]*$/d' "${VOLUME_PATH}"/etc/crontab > "${VOLUME_PATH}"/etc/crontab2
    mv -f "${VOLUME_PATH}"/etc/crontab2 "${VOLUME_PATH}"/etc/crontab
  fi
fi

if [ ! -d "${VOLUME_PATH}"/usr/local/sbin ]
then
  mkdir -p "${VOLUME_PATH}"/usr/local/sbin
  chmod 755 "${VOLUME_PATH}"/usr/local
  chmod 755 "${VOLUME_PATH}"/usr/local/sbin
  chown root:wheel "${VOLUME_PATH}"/usr/local
  chown root:wheel "${VOLUME_PATH}"/usr/local/sbin
fi
cp "${SCRIPT_PATH}"/ds_netboot_restart/ds_netboot_restart.sh "${VOLUME_PATH}"/usr/local/sbin/ds_netboot_restart.sh
chmod 700 "${VOLUME_PATH}"/usr/local/sbin/ds_netboot_restart.sh
chown root:wheel "${VOLUME_PATH}"/usr/local/sbin/ds_netboot_restart.sh

echo "${SCRIPT_NAME} - end"

exit 0
