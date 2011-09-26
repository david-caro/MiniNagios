#!/bin/bash

usage()
{
    echo "Usage $0"
    exit 2
}




pluginsdir="${0%/*}/aux"
source $pluginsdir/config_loader.sh
load ${0##*/}

### Config
maxlimit=${maxlimit:=90}

error=0
disk=""
percent=""

for dev in $(df -h | grep "^/dev/" | awk '{ print $1 "_" $5 }')
do
    disk="$(echo $dev | cut -d'_' -f1)"
    percent="$(echo $dev | cut -d'_' -f2 | sed -e 's|%||')"
    if [ $percent -ge $maxlimit ]
    then
        error=1
        error_msg+="Disk at $disk has $percent of the space used (limit: $maxlimit)\n\t"
    else
        error_msg+="Disk at $disk has $percent of the space used (limit: $maxlimit)\n\t"
    fi
done

if [ $error -eq 1 ]
then
    echo -e "DISK ERROR:\n\t$error_msg"
    exit 2
else
    echo -e "DISK OK:\n\t$error_msg"
fi




