#!/bin/bash

tmp_dir="/tmp"
tmp_mailfile="$tmp_dir/mininagios_mailfile"
tmp_errormsgfile="$tmp_dir/mininagios_lasterror"
tmp_statusfile="$tmp_dir/mininagios_laststatus"

homedir="$(dirname $0)"

error_msg=""
error=0
res=0
send=0

source ${0%/*}/config

timestamp="$(date)"

redir()
{
   exec 4>&1-
   [ -f $tmp_mailfile ] && rm -f $tmp_mailfile &>/dev/null
   exec 1>>$1
}
unredir()
{
   exec 1>&4-
}

## send_mail(error, error_msg)
send_mail()
{
    redir $tmp_mailfile
    to="${sendto[@]}"
    echo "From:$sendfrom" 
    echo "To:${to// /,}" 
    echo -n "Subject:"
    [ $error -eq 0 ] \
        && echo "$sitename OK" \
        || echo "$sitename ERROR"
    echo "" 
    echo "Report at date $timestamp:"
    echo -e "$error_msg"
    unredir
    cat $tmp_mailfile | /usr/sbin/sendmail -t \
    || echo "ERROR SENDING EMAIL, ERROR LOG SAVED AT $tmp_mailfile"
}

## check_lasterror(error): send
check_lasterror()
{
    errorcode=$1
    [ -f $tmp_errormsgfile ] \
        && lasterror=1 \
        || lasterror=0
    [ -f $tmp_statusfile ] \
        && laststatus="$(head -n1 $tmp_statusfile | egrep -o '[[:digit:]]*' )" \
        || laststatus=0
    ## if there was an error before but there is no error now, send error solved
    ## email and reset status
    if [ $lasterror -eq 1 ] && [ $errorcode -eq 0 ]; then
        rm -f $tmp_statusfile &>/dev/null
        return 1
    ## but if there was no error before but there is one now, send new error 
    ## email
    elif [ $lasterror -eq 0 ] && [ $errorcode -ge 1 ]; then
        echo "$error_msg" > $tmp_errormsgfile
        echo "$errorcode" > $tmp_statusfile
        return 2
    ## and if there was an error and the error changd, update the status and 
    ## send status change email
    elif [ "$laststatus" != "$errorcode" ]; then
        echo "Status changed from $laststatus to $errorcode."
        echo "$errorcode" > $tmp_statusfile
        return 3
    fi
    return 4
}


## execute_checks(): error
execute_checks()
{
    #little remainder
    #error it's a variable containing the error codes returned by the scripts
    #error_msg is the message returned by the scripts
    #send 1 if there is some mail to send (aka the state changed, 
    #error -> solved, solved -> error)
    #$tmp_errormsgfile is the last error message
    #/tmp/lasstatus is the last status
    ######### MAIN ############
    i=1
    for check in $(ls $homedir/checks/*.sh)
    do
        if [ -x $check ]
        then
            error_msg="$error_msg\n\n"
            error_msg+="::::::::::::::::CHECK ${check##*/} :::::::::::::::\n"
            error_msg+="$($check 2>&1 3>&1)"
            error=$(( $error + $?*$i ))
            i=$(( $i*10 ))
        fi
    done
    return $error
}

## execute_checks() : error
execute_checks
## check_lasterror(error): send
check_lasterror $?
case $? in
    1)
        echo "Error solved, sending mail"
        error_msg="Errors solved, you can go to sleep now XD \n$error_msg"
        error_msg+="\n\n::::::::::::::::::::::Last error_msg:::::::::::::::"
        error_msg+="$(cat $tmp_errormsgfile)"
        rm -f $tmp_errormsgfile &>/dev/null
        send_mail
        ;;
    2)
        echo "New error, sending mail"
        send_mail
        ;;
    3)
        echo "Error status changed" 
        send_mail
        ;;
    4)
        [ $error -gt 0 ] \
            && echo "Still got error" \
            || echo "Everithing remains OK"
        ;;
esac

