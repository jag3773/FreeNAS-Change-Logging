FreeNAS-Change-Logging README
==========


Overview
----------

This script allows you to change the location of the logging on an existing
FreeNAS 8 system.  This is helpful if you want to enable persistent logging on
your server without having to setup a remote syslog server.

Typically, you will want to change the logging directory to somewhere on a
dataset.

Please note that running this script will change the way the restore factory
default function works.  However, if you run the --reset option of this script
then it will restore the original factory default filesystem.  Also, note that
the script makes a backup of the configuration files that it changes.

Boot messages will likely not appear in the messages log anymore, since the
persistent storage device is usually mounted toward the end of the boot
process.  To see this messages on a running system you can always run `dmesg`.


Files Modified
----------

The following files are modified by this script:

    /conf/base/etc/newsyslog.conf
    /conf/base/etc/periodic.conf
    /conf/base/etc/syslog.conf

Existing log files are also copied to the new log destination.


Usage
----------

Download the script and make it executable, you'll need to cd into a directory
that is writable:

    cd /mnt/tank0
    fetch https://raw.github.com/jag3773/FreeNAS-Change-Logging/master/FreeNAS-Change-Logging.sh
    chmod +x FreeNAS-Change-Logging.sh

To change the location of the logging from /var/log (the default), run:

    ./FreeNAS-Change-Logging.sh -d <New_Log_Directory>

NOTE: The script will create the logging directory you pass to it if it does
not exist already.

To revert back to the factory default (/var/log), run:

    ./FreeNAS-Change-Logging.sh -r

If you change the logging to a custom location and later want to change it to
a different custom location, then you must reset the logging first.  As an
example:

    ./FreeNAS-Change-Logging.sh -d /mnt/tank0/oops
    ./FreeNAS-Change-Logging.sh -r
    ./FreeNAS-Change-Logging.sh -d /mnt/tank0/log

