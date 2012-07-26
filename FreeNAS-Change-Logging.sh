#!/bin/sh
#  Copyright (c) 2012, Jesse Griffin <jag3773@gmail.com>
#  All rights reserved.
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions are met:
#
#    Redistributions of source code must retain the above copyright notice,
#      this list of conditions and the following disclaimer.
#    Redistributions in binary form must reproduce the above copyright notice,
#      this list of conditions and the following disclaimer in the
#      documentation and/or other materials provided with the distribution.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
#  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
#  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
#  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#  POSSIBILITY OF SUCH DAMAGE.

PROGNAME="${0##*/}"
USAGE="Call the program like this: $PROGNAME -d <New_Log_Directory>"

echo
echo "This script will modify newsyslog.conf, syslog.conf and periodic.conf."
echo "This script assumes that logging is currently set to /var/log, which is"
echo "the default location."
echo "This script will also remove /var/log and make /var/log a symlink to the"
echo "directory that you provide."
echo .
echo -n "Would you like to continue? (y/n) "
read -e CONTINUE
test "$CONTINUE" != "y" && exit 1

# Grab logging directory variable from command line
if [ $# -lt 1 ]; then
  echo $USAGE
  exit 1
fi

while test -n "$1"; do
  case "$1" in
    --directory|-d)
      LOGDIR=$2
      shift
      ;;
    *)
      echo "Unknown argument: $1"
      echo $USAGE
      exit 1
      ;;
  esac
  shift
done

echo "Mounting / as writable..."
mount -uw /

# Verify logging directory exists, if not, create it
echo "Checking for $LOGDIR..."
test -d "$LOGDIR"  || mkdir "$LOGDIR"

echo "Making changes to configuration files..."
# Stop syslogd
/etc/rc.d/syslogd stop

# Modify appropriate files for logging
printf "daily_output=\"$LOGDIR/daily.log\"\n" >> /conf/base/etc/periodic.conf
printf "weekly_output=\"$LOGDIR/weekly.log\"\n" >> /conf/base/etc/periodic.conf
printf "monthly_output=\"$LOGDIR/monthly.log\"\n" >> /conf/base/etc/periodic.conf
echo $LOGDIR | sed 's/\//\\\//g' > /tmp/escapedloggingdir
ESCAPEDDIR=`cat /tmp/escapedloggingdir`
/usr/bin/sed -i.orig "s/\/var\/log/$ESCAPEDDIR/" /conf/base/etc/newsyslog.conf \
/conf/base/etc/syslog.conf

# Copy modified files to existing /
cp -f /conf/base/etc/newsyslog.conf /etc/
cp -f /conf/base/etc/syslog.conf /etc/
cp -f /conf/base/etc/periodic.conf /etc/

# Copy existing log files to $LOGDIR
echo "Copying existing log files to new log directory, answer no to any file"
echo "that you do not want to overwrite..."
cp -ai /var/log/* "$LOGDIR/"

# Link /var/log to $LOGDIR
rm -rf /var/log
ln -s "$LOGDIR" /var/log
rm -rf /conf/base/var/log
ln -s "$LOGDIR" /conf/base/var/log

# Start syslogd
/etc/rc.d/syslogd start

# Remount / as read only
echo "Mounting / as read only..."
mount -ur /

echo "Logging successfully redirected to $LOGDIR."
echo "You may want to reboot to verify that the changes persist."
