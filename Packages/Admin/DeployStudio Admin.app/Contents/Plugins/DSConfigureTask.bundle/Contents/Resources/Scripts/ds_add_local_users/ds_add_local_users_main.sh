#!/bin/sh

echo "ds_add_local_users_main.sh - v1.3 ("`date`")"

#
# Create users
#
if [ -e "/etc/deploystudio/bin/ds_add_local_users.sh" ]
then
  /etc/deploystudio/bin/ds_add_local_users.sh
fi

#
# Remove local users creation scripts
#
/usr/bin/srm -mf /etc/deploystudio/bin/ds_add_local_user.sh
/usr/bin/srm -mf /etc/deploystudio/bin/ds_add_local_users.sh
/usr/bin/srm -mf "${0}"
