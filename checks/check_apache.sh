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
error_msg="APACHE ERROR: "

$pluginsdir/check_tcp.sh localhost $apacheport > /dev/null
if [ $? -ne 0 ]
then
    error=1
    error_msg="${error_msg}Can't connect to localhost:$apacheport\n\t"
fi
apache_procs="$($pluginsdir/check_proc.sh apache2 $minprocs $maxprocs | sed -e 's|.*: \([[:digit:]][[:digit:]]*\).*|\1|')"
if [ $? -ne 0 ]
then
    error=1
    error_msg="${error_msg}There are $apache_procs apache2 processes (max:$maxprocs min:$minprocs)\n\t"
fi
salida="$(wget -O - localhost:$apacheport 2>&1)"
if [ $? -ne 0 ]
then
    error=1
    error_msg="${error_msg}Can't get apache htttp response, output: $salida"
fi

if [ $error -eq 1 ]
then
    echo $error_msg
    exit 2
else
    echo "APACHE OK: Responding at port $apacheport and $apache_procs apache2 processes running."
fi




