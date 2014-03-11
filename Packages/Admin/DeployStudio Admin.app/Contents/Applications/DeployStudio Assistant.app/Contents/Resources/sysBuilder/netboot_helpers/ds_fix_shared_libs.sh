#!/bin/sh

OTOOL=`dirname "${0}"`/../common/otool

########################################################
# Functions
########################################################

update_shared_libs_list() {
  LIBS_COUNT=0
  MISSING_COUNT=0
  FIXED_COUNT=0

  LIBS_IN_USE=""
  
  LOOP_COUNT=`expr ${LOOP_COUNT} + 1`

  if [ ${LOOP_COUNT} == 1 ]
  then
    find "${TARGET_VOLUME}" -type f -perm +111 -exec "${OTOOL}" -L "{}" \; > /tmp/check-libs.${$}
  else
	rm /tmp/check-libs.${$}
	JUST_ADDED_LIBS=`cat /tmp/check-just-added-libs.${$}`
	for ADDED_LIB in ${JUST_ADDED_LIBS}
	do
      find "${TARGET_VOLUME}${ADDED_LIB}" -type f -perm +111 -exec "${OTOOL}" -L "{}" \; >> /tmp/check-libs.${$}
    done
  fi
  sed -e '/^\//d' /tmp/check-libs.${$} | awk '{ print $1 }' \
	    | sed -e '/^@/d' -e '/^\/BinaryCache/d' -e '/^\/var\/tmp/d' -e '/^\/usr\/local/d' \
	    | sort -u > /tmp/check-libs-clean.${$}
  LIBS_COUNT=`cat /tmp/check-libs-clean.${$} | wc -l`
  LIBS_IN_USE=`cat /tmp/check-libs-clean.${$}`

  if [ -e /tmp/check-just-added-libs.${$} ]
  then
    rm /tmp/check-just-added-libs.${$}
  fi
}

########################################################
# Main
########################################################

if [ ${EUID} -ne 0 ]
then
  echo "You need root privileges to run this script!"
  exit 1
fi

if [ ${#} -eq 0 ] || [ ${#} -gt 2 ]
then
  echo "Usage:   ds_fix_shared_libs.sh <target volume> [<reference volume>]"
  echo "Example: ds_fix_shared_libs.sh /Volumes/DeployStudioRuntimeHD /Volumes/OSX_108_HD"
  exit 1
fi

if [ -n "${1}" ] && [ -d "${1}" ]
then
  TARGET_VOLUME="${1}"
elif [ -n "${1}" ] && [ -d "/Volumes/${1}" ]
then
  TARGET_VOLUME="/Volumes/${1}"
fi
if [ -z "${TARGET_VOLUME}" ] || [ ! -d "${TARGET_VOLUME}" ]
then
  echo "'${TARGET_VOLUME}' target volume not found, aborting!"
  exit 1
fi

if [ -z "${2}" ]
then
  REF_VOLUME=""
elif [ -n "${2}" ] && [ -d "${2}" ]
then
  REF_VOLUME="${2}"
elif [ -n "${2}" ] && [ -d "/Volumes/${2}" ]
then
  REF_VOLUME="/Volumes/${2}"
else
  echo "'${2}' reference volume not found, aborting!"
  exit 1
fi

LOOP_COUNT=0

update_shared_libs_list
for LIB in ${LIBS_IN_USE}
do
  if [ ! -e "${TARGET_VOLUME}${LIB}" ] && [ -e "${REF_VOLUME}${LIB}" ]
  then
    MISSING_COUNT=`expr ${MISSING_COUNT} + 1`
	LIB_PATH=`echo "${LIB}" | sed s/".framework\/".*/\.framework/`
	echo "Adding lib '${REF_VOLUME}${LIB_PATH}'"
    rsync --archive --links --delete "${REF_VOLUME}${LIB_PATH}" `dirname "${TARGET_VOLUME}${LIB_PATH}"`
    #ditto --rsrc "${REF_VOLUME}${LIB_PATH}" "${TARGET_VOLUME}${LIB_PATH}"
	if [ ${?} -eq 0 ]
	then
      echo "${LIB_PATH}" >> /tmp/check-just-added-libs.${$}
	  FIXED_COUNT=`expr ${FIXED_COUNT} + 1`
	fi
  fi
done
echo "<loop ${LOOP_COUNT}> ${LIBS_COUNT} linked shared libs (${MISSING_COUNT} missing, ${FIXED_COUNT} fixed)."

while [ ${MISSING_COUNT} -gt 0 ]
do
  update_shared_libs_list
  for LIB in ${LIBS_IN_USE}
  do
    if [ ! -e "${TARGET_VOLUME}${LIB}" ] && [ -e "${REF_VOLUME}${LIB}" ]
    then
      MISSING_COUNT=`expr ${MISSING_COUNT} + 1`
      LIB_PATH=`echo "${LIB}" | sed s/".framework\/".*/\.framework/`
      echo "Adding lib '${REF_VOLUME}${LIB_PATH}'"
      rsync --archive --links --delete "${REF_VOLUME}${LIB_PATH}" `dirname "${TARGET_VOLUME}${LIB_PATH}"`
      #ditto --rsrc "${REF_VOLUME}${LIB_PATH}" "${TARGET_VOLUME}${LIB_PATH}"
      if [ ${?} -eq 0 ]
      then
        echo "${LIB_PATH}" >> /tmp/check-just-added-libs.${$}
        FIXED_COUNT=`expr ${FIXED_COUNT} + 1`
	  fi
    fi
  done
  echo "<loop ${LOOP_COUNT}> ${LIBS_COUNT} linked shared libs (${MISSING_COUNT} missing, ${FIXED_COUNT} fixed)."
done

rm /tmp/check-* &>/dev/null

exit 0
