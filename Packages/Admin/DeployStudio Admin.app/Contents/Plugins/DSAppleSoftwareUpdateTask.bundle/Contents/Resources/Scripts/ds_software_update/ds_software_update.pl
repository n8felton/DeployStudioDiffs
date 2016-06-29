#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;

$ENV{COMMAND_LINE_INSTALL} = 1;

print basename($0) . " - v1.9 (" . localtime(time) . ")\n";

# Wait for network services to be initialized
print "Checking for the default route to be active...\n";
my $ATTEMPTS = 0;
my $MAX_ATTEMPTS = 18;
while (system("netstat -rn -f inet | grep -q default") != 0) {
    if ($ATTEMPTS <= $MAX_ATTEMPTS) {
        print "Waiting for the default route to be active...\n";
        sleep 10;
        $ATTEMPTS++;
    } else {
        print "Network not configured, software update failed ($MAX_ATTEMPTS attempts), will retry at next boot!\n";
        exit 1;
    }
}

# Checking SUS reachability...
print "Checking server reachability...\n";
my $SUS_HOST_NAME = "__SUS_HOST_NAME__";
my $RESET_WHEN_DONE = "__RESET_WHEN_DONE__";
if (length($SUS_HOST_NAME) > 0) {
    if (system("ping -c 1 -n -t 10 \"$SUS_HOST_NAME\" &>/dev/null") != 0) {
        print "The Software Update server '$SUS_HOST_NAME' is not reachable, skipping...\n";
   
        # Reset local SUS url if required
        if (length($RESET_WHEN_DONE) > 0) {
            system("/bin/rm -f /Library/Preferences/com.apple.SoftwareUpdate.plist");
        }
        
        # Self removal
        system("/bin/rm -f \"$0\"");

        exit 200;
    }
}

# Check if updates are available
print "Checking if updates are available...\n";
my @SUS_OUTPUT = qx(/usr/sbin/softwareupdate -l 2>/dev/null);
my @AVAILABLE_UPDATES=grep(/^  *\\*/, @SUS_OUTPUT);
if (@AVAILABLE_UPDATES > 0) {
    my @RESTART_REQUIRED=grep(/\[restart\]/, @SUS_OUTPUT);
    while (@AVAILABLE_UPDATES > 0) {
        # Remove trailing newlines
        chomp(@AVAILABLE_UPDATES);

        # Run Apple Software Update client from the CLI
        print "Installing all updates available (" . @AVAILABLE_UPDATES . ")...\n";
        system('/usr/sbin/softwareupdate -i -a');

        # Restart if required by installed updates
        if (@RESTART_REQUIRED > 0) {
          exit 100;
        }

        # Disable installed updates temporarily
        print "Temporarily disabling installed updates...\n";
        foreach (@AVAILABLE_UPDATES) {
          chomp;
          s/^ *\* *//;
          system("/usr/sbin/softwareupdate --ignore \"$_\"");
        }
        
        # Check if updates are available
        print "Checking if updates are available...\n";
        @SUS_OUTPUT = qx(/usr/sbin/softwareupdate -l 2>/dev/null);
        @AVAILABLE_UPDATES=grep(/^  *\\*/, @SUS_OUTPUT);
        @RESTART_REQUIRED=grep(/\[restart\]/, @SUS_OUTPUT);
    }
} else {
    print "No new software available...\n";

    # Reset previously ignored updates
    system("/usr/sbin/softwareupdate --reset-ignored");

    # Reset local SUS url if required
    if (length($RESET_WHEN_DONE) > 0) {
        system("/bin/rm -f /Library/Preferences/com.apple.SoftwareUpdate.plist");
        system("/bin/rm -f /Library/Preferences/com.apple.SoftwareUpdate.plist.lockfile");
    }

    # Self removal
    system("/bin/rm -f \"$0\"");
    
    exit 200;
}

exit 0;
