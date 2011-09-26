#!/bin/bash

## load section file
# This function loads the given section from the given config file, the config 
# file must have the following structure:
#
# [section1]
# var1=value1
# var2=( var2val1, var2val2 )
# var3="lol${var1}"
#
# [section 2]
# var1=value1
#
# [section1]
# I_forgot_this_var=value
#
# Things it will load:
#   · pairs 'var=value'
#   · arrays in just one line 'var=(value1 value2 value3)'
#   · all the vars even if the section is divided in two
#
# Things it will not load:
#   · pairs 'var=value number one' that will not be correct under bash
#

function load 
{
    section=${1:-default}
    file=${2:-../config}

    [ ! -f $file ] && echo "Config file '$file' not found!" && return 1
    echo "Loading $section from $file."

    i=0 
    while read property
    do
        name="${property%%=*}"
        value="${property#*=}"
        varsub="$(echo $value \
                    | egrep '\${[^}]*}' \
                    | sed -e 's|${\([^}]*\)}|\1|')"
        if [ "$varsub" != "" ]
        then
            varnew="${varsub//./_}"
            value="${value//$varsub/$varnew}"
        fi
            eval "$name=$value"
        i=$(($i+1))
    done < <( sed -n "/^\\[$section\\]/,/^\\[.*\\]/p" $file \
                | egrep "^[^#=]+=.*" )
}

