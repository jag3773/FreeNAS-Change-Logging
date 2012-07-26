#!/bin/bash
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
USAGE="Call the program like this:
'$PROGNAME -d <New_Log_Directory>' to change logging location, or
'$PROGNAME -r' to reset to factory default."

# Check for arguments
if [ $# -lt 1 ]; then
  echo $USAGE
  exit 1
fi

# Grab variables from command line
while test -n "$1"; do
  case "$1" in
    --directory|-d)
      LOGDIR=$2
      shift
      ;;
    --reset|-r)
      RESET="TRUE"
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

# Mount / as writable
mount -uw /

if [ "$RESET" == "TRUE" ]; then
  echo
  echo "Resetting to defaults..."
  echo "Reset only works if you ran this script to change the log directory"
  echo -n "Would you like to continue? (y/n) "
  read -e RESETCONTINUE
  test "$RESETCONTINUE" != "y" && exit 1
  /etc/rc.d/syslogd stop
  cp -f /conf/base/etc/newsyslog.conf.orig /conf/base/etc/newsyslog.conf
  cp -f /conf/base/etc/newsyslog.conf /etc/
  cp -f /conf/base/etc/syslog.conf.orig /conf/base/etc/syslog.conf
  cp -f /conf/base/etc/syslog.conf /etc/
  cp -f /conf/base/etc/periodic.conf.orig /conf/base/etc/periodic.conf
  cp -f /conf/base/etc/periodic.conf /etc/
  rm -f /conf/base/var/log
  cp -a -f /conf/base/var/log.orig /conf/base/var/log
  rm -f /var/log
  cp -a -f /conf/base/var/log /var/
  /etc/rc.d/syslogd start
  mount -ur /
  echo
  echo "Logging environment returned to factory default."
  exit 0
fi

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

# Verify logging directory exists, if not, create it
test -d "$LOGDIR"  || mkdir "$LOGDIR"

echo "Making changes to configuration files..."
# Stop syslogd
/etc/rc.d/syslogd stop

# Modify appropriate files for logging
cp /conf/base/etc/periodic.conf /conf/base/etc/periodic.conf.orig
/usr/bin/grep "daily.log" /conf/base/etc/periodic.conf || \
printf "daily_output=\"$LOGDIR/daily.log\"\n" >> /conf/base/etc/periodic.conf
/usr/bin/grep "weekly.log" /conf/base/etc/periodic.conf || \
printf "weekly_output=\"$LOGDIR/weekly.log\"\n" >> /conf/base/etc/periodic.conf
/usr/bin/grep "monthly.log" /conf/base/etc/periodic.conf || \
printf "monthly_output=\"$LOGDIR/monthly.log\"\n" >> /conf/base/etc/periodic.conf
echo $LOGDIR | sed 's/\//\\\//g' > /tmp/escapedloggingdir
ESCAPEDDIR=`cat /tmp/escapedloggingdir`
/usr/bin/sed -i.orig "s/\/var\/log/$ESCAPEDDIR/" /conf/base/etc/newsyslog.conf \
/conf/base/etc/syslog.conf
rm /tmp/escapedloggingdir

# Copy modified files to existing /
cp -f /conf/base/etc/newsyslog.conf /etc/
cp -f /conf/base/etc/syslog.conf /etc/
cp -f /conf/base/etc/periodic.conf /etc/

# Copy existing log files to $LOGDIR
echo "Copying existing log files to new log directory, answer no to any file"
echo "that you do not want to overwrite..."
cp -ai /var/log/* "$LOGDIR/"
cp -af /conf/base/var/log /conf/base/var/log.orig

# Link /var/log to $LOGDIR
rm -rf /var/log
ln -s "$LOGDIR" /var/log
rm -rf /conf/base/var/log
ln -s "$LOGDIR" /conf/base/var/log

# Start syslogd
/etc/rc.d/syslogd start

# Mount / as read only
mount -ur /

echo
echo "Logging successfully redirected to $LOGDIR."
echo "You may want to reboot to verify that the changes persist."
