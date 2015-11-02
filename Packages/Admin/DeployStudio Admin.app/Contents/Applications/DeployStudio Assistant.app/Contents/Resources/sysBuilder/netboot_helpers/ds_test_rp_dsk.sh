SYS_VERS=`sw_vers -productVersion | sed s/"\."//`
/Applications/Utilities/DeployStudio\ Assistant.app/Contents/Resources/sysBuilder/sys_builder_rp.sh \
   -basesystem / \
   -type local \
   -volume "DeployStudioRuntimeHD" \
   -loc default \
   -timeout 30 \
   -displaysleep 30 \
   -disablewirelesssupport \
   -custombackground /tmp/DSCustomDefaultDesktop.jpg \
   -ntp time.euro.apple.com \
   -serverurl https://127.0.0.1:60443 \
   -login admin \
   -ardlogin admin \
   -ardpassword apple \
   -displaylogs
