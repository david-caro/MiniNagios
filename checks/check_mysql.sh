#!/bin/bash

usage()
{
    echo "Usage $0"
    exit 2
}

#### Config
mysqlport=3306
maxprocs=20
minprocs=1
maxquerytime=30
mysqluser="root"
mysqlpass="w4t3rm41l0n-DB"



pluginsdir="${0%/*}/aux"
error=0

## check how many mysql procs are running
mysql_procs="$($pluginsdir/check_proc.sh mysqld $minprocs $maxprocs 2>/dev/null 3>&2)"
if [ $? -ne 0 ]
then
    error=1
    error_msg+="${mysql_procs#*: }\n\t"
fi

## check if somebody is listening
$pluginsdir/check_tcp.sh localhost $mysqlport &> /dev/null
if [ $? -ne 0 ]
then
    error=1
    error_msg+="Can't connect to localhost $mysqlport\n\t"
fi

## check if the daemon is responsive
[ $error -eq 0 ] \
&& mysql_output="$(mysql -p$mysqlpass -u$mysqluser -e'Select 1' 2>&1 3>&1)"
if [ $? -ne 0 ] && [ $error -eq 0 ]
then
    error=1
    error_msg+="Can't execute Select 1 at localhost, output: $mysql_output\n\t"
fi

## check how much time the oldest query has been running
[ $error -eq 0 ] && mysql_query_time="$(\
    mysql -p$mysqlpass -u$mysqluser -e "show full processlist;" 2>/dev/null 3>&2\
    | grep -iv sleep | grep -v "^Id" | awk '{ print $6 }' | sort -r \
    | head -n1 2>/dev/null 3>&2)"
if [ $error -eq 0 ] && [ "$mysql_query_time" != "" ]
then
    if [ $mysql_query_time -gt $maxquerytime ]
    then
        error_msg+="There's at least one query with "
        error_msg+="more than $mysql_query_time seconds of execution time\n\t"
        error_msg+="$(mysql -p$mysqlpass -u$mysqluser -e 'show full processlist;' 2>/dev/null 3>&2 \
                    | grep -v sleep | grep -v "^Id" | awk '{ print $6,$0 }' | sort -r |head -n2)"
        error=1
    fi
fi

## show the results
if [ $error -eq 1 ]
then
    echo -e "MYSQL ERROR:\n\t$error_msg"
    exit 2
else
    echo -en "MYSQL OK: Responding at $mysqlport "
    echo "and ${mysql_procs#*: }"
    echo "With a max query time of $mysql_query_time"
fi




