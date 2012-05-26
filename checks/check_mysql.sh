#!/bin/bash

usage()
{
    echo "Usage $0"
    exit 2
}

function run
{
    local maxprocs
    local minprocs
    local maxquerytime
    local user
    local pass
    local port
    local host

    pluginsdir="${0%/*}/aux"
    source $pluginsdir/config_loader.sh
    load ${0##*/}
    error=0
    error_msg="MYSQL ERROR:\n\t"
    ok_msg="MYSQL OK:\n\t"

    ## check if somebody is listening at tcp level
    $pluginsdir/check_tcp.sh ${host:=localhost} ${port:=3306} &> /dev/null \
        && ok_msg+="Responding at $host:$port\n\t" \
        || { error=1 && error_msg+="Can't connect to localhost $port\n\t"; }

    [[ $maxprocs ]] && \
    {
        ## check how many mysql procs are running
        mysql_procs="$($pluginsdir/check_proc.sh mysqld ${minprocs=1} $maxprocs 2>/dev/null 3>&2)"
        if [ $? -ne 0 ]
        then
            error=1
            error_msg+="${mysql_procs#*: }\n\t"
        else
            ok_msg+="and ${mysql_procs#*: }\n\t"
        fi
    }
    
    ## check if the daemon is responsive
    [ $error -eq 0 ] \
        && mysql_output="$(mysql -h$host -p$pass -u$user -e'Select 1' 2>&1 3>&1)"
    if [ $? -ne 0 ] && [ $error -eq 0 ]
    then
        error=1
        error_msg+="Can't execute Select 1 at localhost, output: $mysql_output\n\t"
    fi
    
    ## check how much time the oldest query has been running
    [ $error -eq 0 ] \
        && mysql_query_time="\
        $(\
            mysql -h$host -p$pass -u$user -e "show full processlist;" 2>/dev/null 3>&2\
            | grep -v sleep | grep -v "^Id" | awk '{ print $6 }' | sort -r \
            | head -n1 2>/dev/null 3>&2\
        )"
    [ $error -eq 0 ] \
        && [ "$mysql_query_time" != "" ] \
        && [ $mysql_query_time -gt $maxquerytime ] \
        && {
            error_msg+="There's at least one query with "
            error_msg+="more than ${mysql_query_time// } seconds of execution time\n\t"
            error=1
        } \
        || ok_msg+="With a max query time of $mysql_query_time (max: $maxquerytime)"

    ## show the results
    if [ $error -eq 1 ]
    then
        echo -e "$error_msg"
        return 2
    else
        echo -e "$ok_msg"
    fi
}

run

