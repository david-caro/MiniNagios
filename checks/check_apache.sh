#!/bin/bash

usage()
{
    echo "Usage $0"
    exit 2
}

#### Config
apacheport=80
minprocs=1
maxprocs=65


pluginsdir="$(dirname $0)/aux"
error=0
error_msg="APACHE ERROR: \n\t"

$pluginsdir/check_tcp.sh localhost $apacheport > /dev/null
if [ $? -ne 0 ]
then
    error=1
    error_msg+="Can't connect to localhost:$apacheport\n\t"
fi

apache_procs="$($pluginsdir/check_proc.sh apache2 $minprocs $maxprocs)"
if [ $? -ne 0 ]
then
    error=1
    error_msg+=" ${apache_procs#*: }\n\t"
fi

[ $error -eq 0 ] && salida="$(wget -O - localhost:$apacheport 2>&1)"
if [ $? -ne 0 ] && [ $error -eq 0 ]
then
    error=1
    error_msg+="Can't get apache htttp response, output: $salida"
fi

if [ $error -eq 1 ]
then
    echo -e "$error_msg"
    exit 2
else
    echo "APACHE OK: Responding at port $apacheport and ${apache_proc#*: }"
fi




