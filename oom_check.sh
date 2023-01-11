#!/bin/sh
#set -x
#oom invoke check. This simple script checks if oom-killer was invoked.
#It could be useful when memory monitoring does not respond quickly enough to memory spikes
#please note that you need to add sudoers proviliges for nrpe user to check /var/log/messages
#nrpe    ALL=(root) NOPASSWD:/usr/bin/grep oom-kill /var/log/messages

# exit statuses recognized by Nagios
OK=0
WARNING=1
CRITICAL=2
UNKNOWN=3

#variables
OOM_ACTION_DATE=$(sudo grep oom-kill /var/log/messages | tail -1 | awk '{print $1,$2,$3}')
OOM_ACTION_DATE_EPOCH=$(date -d "$OOM_ACTION_DATE" +"%s")
ACTUAL_DATE=$(date | awk '{print $2,$3,$4}')
ACTUAL_DATE_EPOCH=$(date -d "$ACTUAL_DATE" +"%s")
DATE_DELAY_CRIT=$(($ACTUAL_DATE_EPOCH - 40000))
DATE_DELAY_WARN=$(($ACTUAL_DATE_EPOCH - 80000))

#compare
if [ "$OOM_ACTION_DATE" = "" ];
then
    echo "oom-killer was never invoked (in the last logfile)"
    EXIT=0 
elif [ "$OOM_ACTION_DATE_EPOCH" -gt "$DATE_DELAY_CRIT" ];
then
    echo "CRITICAL! Some process on the server was killed, oom-killer was invoked, call forensics"
    EXIT=2
elif [ "$OOM_ACTION_DATE_EPOCH" -gt "$DATE_DELAY_WARN" ];
then
    echo "WARNING! oom-killer was envoked recently"
    EXIT=1
else
    echo "OK! oom was not invoked recently"
    EXIT=0
fi
