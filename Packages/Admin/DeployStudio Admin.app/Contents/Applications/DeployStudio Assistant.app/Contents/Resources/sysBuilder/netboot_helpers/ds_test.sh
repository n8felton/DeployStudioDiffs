SYS_VERS=`sw_vers -productVersion | sed s/"\."//`
/Applications/Utilities/DeployStudio\ Assistant.app/Contents/Resources/sysBuilder/sys_builder.sh \
   -basesystem / \
   -type netboot \
   -id "${SYS_VERS}" \
   -dest /tmp/ \
   -name "DSR-${SYS_VERS}" \
   -loc default \
   -timeout 30 \
   -displaysleep 10 \
   -disablewirelesssupport \
   -custombackground /tmp/DSCustomDefaultDesktop.jpg \
   -ntp time.euro.apple.com \
   -serverurl https://127.0.0.1:60443 \
   -login admin \
   -ardlogin admin \
   -ardpassword apple \
   -displaylogs
