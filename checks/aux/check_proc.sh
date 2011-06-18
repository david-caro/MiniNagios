#!/bin/bash



usage()
{
    echo "Usage: $0 procname min_num_procs max_num_procs"
    exit 1
}


if [ $# -ne 3 ]
then
    usage
fi

proc=$1
min_num_procs=$2
max_num_procs=$3

num_procs="$(pgrep $proc | wc -l)"

if [ $num_procs -lt $min_num_procs ] || [ $num_procs -gt $max_num_procs ]
then
    echo -n "PROC ERROR: $num_procs $proc processes "
    echo "(max:$max_num_procs min:$min_num_procs)."
    exit 2
else
    echo -n "PROC OK: $num_procs $proc processes "
    echo "(max:$max_num_procs min:$min_num_procs)."
    exit 0
fi
