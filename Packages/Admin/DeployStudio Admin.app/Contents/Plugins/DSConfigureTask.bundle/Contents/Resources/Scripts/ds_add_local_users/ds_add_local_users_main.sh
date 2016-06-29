#!/bin/sh

echo "ds_add_local_users_main.sh - v1.5 ("`date`")"

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
rm -Pf /etc/deploystudio/bin/ds_add_local_user.sh
rm -Pf /etc/deploystudio/bin/ds_add_local_users.sh
rm -f "${0}"
exit 0