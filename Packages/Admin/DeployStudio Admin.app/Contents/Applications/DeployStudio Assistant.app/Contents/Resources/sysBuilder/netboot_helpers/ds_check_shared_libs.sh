#!/bin/sh

OTOOL=`dirname "${0}"`/../common/otool

########################################################
# Functions
########################################################

update_bins_and_libs_list() {
  BINS_COUNT=0
  LIBS_COUNT=0
  MISSING_COUNT=0

  LIBS_IN_USE=""

  find "${TARGET_VOLUME}" -type f -perm +111 > /tmp/check-bins.${$}
  BINS_COUNT=`cat /tmp/check-bins.${$} | wc -l `

  find "${TARGET_VOLUME}" -type f -perm +111 -exec "${OTOOL}" -L "{}" \; > /tmp/check-libs.${$}
  sed -e '/^\//d' /tmp/check-libs.${$} | awk '{ print $1 }' \
	    | sed -e '/^@/d' -e '/^\/BinaryCache/d' -e '/^\/var\/tmp/d' -e '/^\/usr\/local/d' \
	    | sort -u > /tmp/check-libs-clean.${$}
  LIBS_COUNT=`cat /tmp/check-libs-clean.${$} | wc -l`
  LIBS_IN_USE=`cat /tmp/check-libs-clean.${$}`
}

########################################################
# Main
########################################################

if [ ${EUID} -ne 0 ]
then
  echo "You need root privileges to run this script!"
  exit 1
fi

if [ -n "${1}" ] && [ -d "${1}" ]
then
  TARGET_VOLUME="${1}"
elif [ -n "${1}" ] && [ -d "/Volumes/${1}" ]
then
  TARGET_VOLUME="/Volumes/${1}"
elif [ -d "/Volumes/DeployStudioRuntime" ]
then
  TARGET_VOLUME="/Volumes/DeployStudioRuntime"
elif [ -d "/Volumes/DeployStudioRuntimeHD" ]
then
  TARGET_VOLUME=/Volumes/DeployStudioRuntimeHD
fi
if [ ! -d "${TARGET_VOLUME}" ]
then
  echo "${TARGET_VOLUME} volume not found, aborting!"
  exit 1
fi

update_bins_and_libs_list
for LIB in ${LIBS_IN_USE}
do
  if [ ! -e "${TARGET_VOLUME}${LIB}" ] && [ -e "${LIB}" ]
  then
    MISSING_COUNT=`expr ${MISSING_COUNT} + 1`
    echo "Missing lib '${LIB}'"
  fi
done
echo "-> ${BINS_COUNT} binaries linked to ${LIBS_COUNT} shared libs (${MISSING_COUNT} missing)."

rm /tmp/check-*

exit 0
