#!/bin/bash

usage()
{
    echo "Usage $0"
    exit 2
}

### Config
loadlimit=15

error=0
error_msg="LOAD ERROR: "

load="$( cat /proc/loadavg | awk '{ print $2 }' | sed -e 's|\.||g' )"
if [ $load -ge $loadlimit ]
then
    error=1
    error_msg="${error_msg}Load avg at $load (limit: $loadlimit)\n\t"
fi
if [ $error -eq 1 ]
then
    echo $error_msg
    exit 2
else
    echo "LOAD OK: Load average of $(echo $load | sed -e 's|\([[:digit:]][[:digit:]]$\)|.\1|')"
fi




