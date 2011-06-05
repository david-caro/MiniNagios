#!/bin/bash

usage()
{
    echo "Usage $0"
    exit 2
}

### Config
maxlimit=90

error=0
error_header="DISK ERROR: "
disk=""
percent=""

for dev in $(df -h | grep "^/dev/" | awk '{ print $1 "_" $5 }')
do
    disk="$(echo $dev | cut -d'_' -f1)"
    percent="$(echo $dev | cut -d'_' -f2 | sed -e 's|%||')"
    if [ $percent -ge $maxlimit ]
    then
        error=1
    fi
    error_msg="${error_msg}Disk at $disk has $percent of the space filled (limit: $maxlimit)\n\t"
done
if [ $error -eq 1 ]
then
    echo -e "$error_header$error_msg"
    exit 2
else
    echo -e "DISK OK: $error_msg"
fi




