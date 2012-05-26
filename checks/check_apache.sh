#!/bin/bash

usage()
{
    echo "Usage $0"
    exit 2
}

function run()
{
    local host
    local port
    local maxproc
    local minproc
    
    pluginsdir="$(dirname $0)/aux"

    source $pluginsdir/config_loader.sh
    load ${0##*/} 

    error=0
    error_msg="APACHE ERROR: \n\t"
    ok_msg="APACHE OK: Responding at ${host:=localhost}:$port"
    
    
    
    # Check if the server is responding at tcp level
    if ! $pluginsdir/check_tcp.sh ${host:=localhost} $port > /dev/null
    then
        error=1
        error_msg+="Can't connect to $host:$port\n\t"
    fi
    
    # Check if the max proc number is reached
    [[ $maxprocs ]] && \
    {
        apache_procs="$($pluginsdir/check_proc.sh apache2 ${minprocs:=1} $maxprocs)"
        [ $? -ne 0 ] \
            && error=1 \
            && error_msg+=" ${apache_procs#*: }\n\t" \
            || ok_msg+=" and ${apache_procs#*: }"
    }

        
    # Check if the server is responding at http level
    [ $error -eq 0 ] \
        && salida="$(wget -O - $host:$port 2>&1)"
    if [ $? -ne 0 ] && [ $error -eq 0 ]
    then
        error=1
        error_msg+="Can't get apache http response, output: $salida"
    fi
    
    # Print the result
    if [ $error -eq 1 ]
    then
        echo -e "$error_msg"
        return 2
    else
        echo -e "$ok_msg"
        return 0
    fi
}

run


