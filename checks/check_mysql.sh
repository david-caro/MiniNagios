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
mysqlpass="pass"



pluginsdir="$(dirname $0)/aux"
error=0
error_msg="MYSQL ERROR: "

$pluginsdir/check_tcp.sh localhost $mysqlport > /dev/null
if [ $? -ne 0 ]
then
    error=1
    error_msg="${error_msg}Can't connect to localhost $mysqlport\n\t"
fi
mysql_procs="$($pluginsdir/check_proc.sh mysqld $minprocs $maxprocs | sed -e 's|.*: \([[:digit:]][[:digit:]]*\).*|\1|')"
if [ $? -ne 0 ]
then
    error=1
    error_msg="${error_msg}There are $mysql_procs mysqld processes (max:$maxprocs min:$minprocs)\n\t"
fi
salida="$(mysql -p$mysqlpass -u$mysqluser -e'Select 1' 2>&1)"
if [ $? -ne 0 ]
then
    error=1
    error_msg="${error_msg}Can't execute Select 1 at localhost, output: $salida"
fi

# Mysql query time
mysql_query_time="$(mysql -p$mysqlpass -u$mysqluser -e "show full processlist;" | grep -v sleep | grep -v "^Id" | awk '{ print $6 }' | sort -r| head -n1)"
if ! [ "$mysql_query_time" == "" ]
then
    if [ $mysql_query_time -gt $maxquerytime ]
    then
        error_msg="${error_msg}\nERROR MYSQL::There's at least one query with more than $mysql_query_time seconds of execution time"
    fi
fi


if [ $error -eq 1 ]
then
    echo $error_msg
    exit 2
else
    echo "MYSQL OK: Responding at $mysqlport and $mysql_procs mysqld processes running."
fi




