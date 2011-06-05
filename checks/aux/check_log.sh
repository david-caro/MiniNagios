#!/bin/bash

usage()
{
    echo "Usage: $0 logfile error_msg"
    exit 2
}


if [ $# -ne 2 ]
then
    usage
fi

error_msg="$2"
logfile="$1"

if ! [ -f $logfile ]
then
    echo "LOG ERROR: Logfile $logfile not found."
    exit 2
fi

errors="$(grep $error_msg $logfile)"

total_errors=`echo "$errors" | wc -l`
last_errors="$(echo -e $errors | tail -n 3)"

if [ "$errors" != "" ]
then
    echo -e "LOG ERROR: Found $total_errors errors at logfile $logfile, last three: \n$errors"
    exit 2
else
    echo "LOG OK: Found no errors at logfile $logfile."
    exit 0
fi
