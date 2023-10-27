
#!/bin/sh
#set -x
# This script was written specifically for scenarios where "yum check-update" should be run only once a week to avoid putting unnecessary load on the server.
# To execute this script, add the following line to your crontab:
# 0 5 * * 5	root	/bin/yum check-update > /tmp/yum-update
# The script reads the content of the file /tmp/yum-update and acts based on its content.

#variables
FILE="/tmp/yum-update"

# Check if file exists and is readable
if [[ ! -e $FILE ]]; then
    echo "File does not exist or is unavailable."
    exit 3
elif [[ ! -r $FILE ]]; then
    echo "Permissions on the file are incorrect."
    exit 3
elif grep -qE '^[^\s]+\s+[^\s]+\s+[^\s]+$' "$FILE"; then
    echo "File contains package names."
    exit 2
else
    echo "File doesn't contain valid package listings."
    exit 0
fi
