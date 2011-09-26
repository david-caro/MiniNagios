#!/bin/bash

error=0
res=0
send=0

time=$( date )

usage()
{
    echo "Usage: $0 host port"
    exit 1
}

if [ $# -ne 2 ]
then
    usage
fi

host=$1
port=$2

salida="$(nc -z $host $port 2>&1 )"
if [ $? -ne 0 ]
then
    if [ "$salida" == "" ]
    then 
        echo "TCP ERROR: Port $port at host $host closed."
    else
        echo "TCP ERROR: $salida."
    fi
    exit 2
else
    echo "TCP OK: Port $port at host $host open."
    exit 0
fi
