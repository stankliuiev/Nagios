#!/bin/sh
#wrote by Stan Kliuiev 2022.10.14
#the owner:group of this file must be postgres 
#set -x

latest_backup_date=$(/usr/bin/sed -n '1p' /tmp/backup.txt)
current_date=$(/usr/bin/date +%F)

#[ -z "$latest_backup_date" ] && exit 2
#[ -z "$current_date" ] && exit 2

if [ "$current_date" == "$latest_backup_date" ]
then
    echo "OK - psqldumps are up to date, latest backup has been created today"
    exit 0

elif
    pgrep -F /tmp/backup.pid &>/dev/null

then
    echo "OK - backup is in process, pid file exists"
    exit 0
else
    echo "CRITICAL - backup is not ok, need attention!"
    exit 2
fi

