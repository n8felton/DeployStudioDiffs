#!/bin/sh

SCRIPT_NAME=`basename "${0}"`

echo "${SCRIPT_NAME} - v1.9 ("`date`")"

for P in "${@}"
do
  F=`echo ${P} | awk -F= '{ print $1 }'`
  V=`echo ${P} | awk -F= '{ print $2 }'`
  if [ "${F}" = "-server" ]
  then
    NETBOOT_SERVER=${V}
  elif [ "${F}" = "-nbi" ]
  then
    NETBOOT_NBI=${V}
  elif [ "${F}" = "-force" ]
  then
    FORCE=1
  fi
done

echo "  checking for the default route to be active..."
ATTEMPTS=0
MAX_ATTEMPTS=12
while ! (netstat -rn -f inet | grep -q default)
do
  if [ ${ATTEMPTS} -le ${MAX_ATTEMPTS} ]
  then
    echo "  waiting for the default route to be active..."
    sleep 5
	ATTEMPTS=`expr ${ATTEMPTS} + 1`
  else
    echo "  network not configured (${MAX_ATTEMPTS} attempts), netboot aborted!" 2>&1
	exit 1
  fi
done

if [ `/usr/bin/arch` = "i386" ]
then
  if [ -n "${NETBOOT_SERVER}" ] && [ -n "${NETBOOT_NBI}" ]
  then
    echo "  setting boot device to the netboot set '${NETBOOT_NBI}' on server '${NETBOOT_SERVER}'"
    /usr/sbin/bless --netboot \
                    --server "bsdp://${NETBOOT_SERVER}" \
                    --options "rp=nfs:${NETBOOT_SERVER}:/private/tftpboot/NetBoot/NetBootSP0:${NETBOOT_NBI}/NetInstall.dmg" \
                    --verbose
  elif [ -n "${NETBOOT_SERVER}" ]
  then
    echo "  setting boot device to server '${NETBOOT_SERVER}'"
    /usr/sbin/bless --netboot \
                    --server "bsdp://${NETBOOT_SERVER}" \
                    --verbose
  else
    echo "  setting boot device to default netboot set"
    /usr/sbin/bless --netboot --server bsdp://255.255.255.255 --verbose
  fi
else
  if [ -n "${NETBOOT_SERVER}" ] && [ -n "${NETBOOT_NBI}" ]
  then
    echo "  setting boot device to the netboot set '${NETBOOT_NBI}' on server '${NETBOOT_SERVER}'"
    /usr/sbin/nvram boot-device="enet:${NETBOOT_SERVER},\\private\\tftpboot\\NetBoot\\NetBootSP0\\${NETBOOT_NBI}\\ppc\\booter"
    /usr/sbin/nvram boot-file="enet:${NETBOOT_SERVER},\\private\\tftpboot\\NetBoot\\NetBootSP0\\${NETBOOT_NBI}\\ppc\\mach.macosx"
    /usr/sbin/nvram boot-args="boot-args rp=nfs:${NETBOOT_SERVER}:/private/tftpboot/NetBoot/NetBootSP0:${NETBOOT_NBI}/NetInstall.dmg" * reboot
  else
    echo "  setting boot device to default netboot set"
    /usr/sbin/nvram boot-device="enet:bootp"
  fi
fi

if [ ${FORCE} -eq 1 ]
then
  echo "  restarting now..."
  /sbin/reboot
else
  echo "  restarting with care, logged user will be prompted to save the edited documents..."
  /usr/bin/osascript -e 'tell application "Finder" to restart'
fi

echo "${SCRIPT_NAME} - end"

exit 0
