#!/bin/sh
#wrote by Stan Kliuiev 2022.10.14
#the owner:group of this file must be postgres 
#set -x

latest_backup_date=$(ls -td -- /var/lib/pgsql/backup/* | head -n 1);
current=$(date +%s);
last_modified=$(stat -c "%Y" $latest_backup_date);

if [ $((current - last_modified)) -lt 86400 ];
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

