#!/bin/sh

echo "ds_example.sh - v1.14 ("`date`")"

#
# DS_USER_LOGIN,
# DS_REPOSITORY_PATH,
# DS_LAST_SELECTED_TARGET,
# DS_LAST_RESTORED_VOLUME,
# DS_LAST_RESTORED_DEVICE,
# DS_LAST_RESTORED_DISK_IMAGE_NAME,
# DS_LAST_CREATED_DISK_IMAGE_NAME,
# DS_BOOT_DEVICE,
# DS_STARTUP_VOLUME,
# DS_HOSTNAME,
# DS_COMPUTERNAME,
# DS_BOOTCAMP_WINDOWS_COMPUTER_NAME,
# DS_BOOTCAMP_WINDOWS_PRODUCT_KEY,
# DS_PRIMARY_MAC_ADDRESS,
# DS_ASSIGNED_IP_ADDRESS,
# DS_ASSIGNED_SUBNET,
# DS_ASSIGNED_ROUTER,
# DS_ASSIGNED_HOSTNAME,
# DS_ASSIGNED_DNS,
# DS_ASSIGNED_DOMAIN,
# DS_COMPUTER_GROUP,
# DS_SUPERDRIVE,
# DS_ARCHITECTURE,
# DS_SERIAL_NUMBER,
# DS_MODEL_IDENTIFIER,
# DS_BOOTROM_VERSION,
# DS_CURRENT_WORKFLOW_TITLE,
# DS_CURRENT_WORKFLOW_ID
# are environment variables defined by DeployStudio Server Runtime
#

echo 'DS_USER_LOGIN                    =('${DS_USER_LOGIN}')'
echo 'DS_REPOSITORY_PATH               =('${DS_REPOSITORY_PATH}')'
echo 'DS_LAST_SELECTED_TARGET          =('${DS_LAST_SELECTED_TARGET}')'
echo 'DS_LAST_RESTORED_VOLUME          =('${DS_LAST_RESTORED_VOLUME}')'
echo 'DS_LAST_RESTORED_DEVICE          =('${DS_LAST_RESTORED_DEVICE}')'
echo 'DS_LAST_RESTORED_DISK_IMAGE_NAME =('${DS_LAST_RESTORED_DISK_IMAGE_NAME}')'
echo 'DS_LAST_CREATED_DISK_IMAGE_NAME  =('${DS_LAST_CREATED_DISK_IMAGE_NAME}')'
echo 'DS_BOOT_DEVICE                   =('${DS_BOOT_DEVICE}')'
echo 'DS_STARTUP_VOLUME                =('${DS_STARTUP_VOLUME}')'
echo 'DS_HOSTNAME                      =('${DS_HOSTNAME}')'
echo 'DS_COMPUTERNAME                  =('${DS_COMPUTERNAME}')'
echo 'DS_BOOTCAMP_WINDOWS_COMPUTER_NAME=('${DS_BOOTCAMP_WINDOWS_COMPUTER_NAME}')'
echo 'DS_BOOTCAMP_WINDOWS_PRODUCT_KEY  =('${DS_BOOTCAMP_WINDOWS_PRODUCT_KEY}')'
echo 'DS_PRIMARY_MAC_ADDRESS           =('${DS_PRIMARY_MAC_ADDRESS}')'
echo 'DS_ASSIGNED_IP_ADDRESS           =('${DS_ASSIGNED_IP_ADDRESS}')'
echo 'DS_ASSIGNED_SUBNET               =('${DS_ASSIGNED_SUBNET}')'
echo 'DS_ASSIGNED_ROUTER               =('${DS_ASSIGNED_ROUTER}')'
echo 'DS_ASSIGNED_HOSTNAME             =('${DS_ASSIGNED_HOSTNAME}')'
echo 'DS_ASSIGNED_DNS                  =('${DS_ASSIGNED_DNS}')'
echo 'DS_ASSIGNED_DOMAIN               =('${DS_ASSIGNED_DOMAIN}')'
echo 'DS_COMPUTER_GROUP                =('${DS_COMPUTER_GROUP}')'
echo 'DS_SUPERDRIVE                    =('${DS_SUPERDRIVE}')'
echo 'DS_ARCHITECTURE                  =('${DS_ARCHITECTURE}')'
echo 'DS_SERIAL_NUMBER                 =('${DS_SERIAL_NUMBER}')'
echo 'DS_MODEL_IDENTIFIER              =('${DS_MODEL_IDENTIFIER}')'
echo 'DS_BOOTROM_VERSION               =('${DS_BOOTROM_VERSION}')'
echo 'DS_CURRENT_WORKFLOW_TITLE        =('${DS_CURRENT_WORKFLOW_TITLE}')'
echo 'DS_CURRENT_WORKFLOW_ID           =('${DS_CURRENT_WORKFLOW_ID}')'

echo 'sleep 1'
sleep 1

#
# Echo a KEY=value pair with the prefix RuntimeSetCustomProperty to make
# DeployStudio Runtime set or update a custom property for the current computer.
#
# Example:
#
# echo "RuntimeSetCustomProperty: MY_CUSTOM_KEY=DeployStudio Rocks!"

#
# Echo a message with the prefix RuntimeAbortWorkflow to alert
# DeployStudio Runtime that the workflow should be aborted.
#
# Example:
#
#if [ "_${error}" = "_1" ]; then
#   echo "RuntimeAbortWorkflow: message"
#fi

echo "ds_example.sh - end"

exit 0
