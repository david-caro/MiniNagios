#!/bin/bash

tmp_mailfile="/tmp/mininagios_mailfile2"
homedir="$(dirname $0)"

error_msg=""
error=0
res=0
send=0

source $(dirname $0)/config

time=$( date )

## send_mail(error, error_msg)
send_mail()
{
    to="${sendto[@]}"
    echo "From:$sendfrom" > $tmp_mailfile
    echo "To:${to// /,}" >> $tmp_mailfile
    [ $error -eq 0 ] \
        && subject="$sitename OK" \
        || subject="$sitename ERROR"
    echo "Subject:$subject" >> $tmp_mailfile
    echo "" >> $tmp_mailfile
    echo "Report at date $time:" >> $tmp_mailfile
    echo -e "$error_msg" >> $tmp_mailfile
    cat $tmp_mailfile | /usr/sbin/sendmail -t \
    || echo "ERROR SENDING EMAIL, ERROR LOG SAVED AT $tmp_mailfile"
}

## check_last_error(error): send
check_lasterror()
{
    error=$1
    if [ -f /tmp/lasterror2 ]
    then
        lasterror=1
    else
        lasterror=0
    fi
    if [ -f /tmp/laststatus ]
    then
        laststatus="$(head -n1 /tmp/laststatus | egrep -o '[[:digit:]]*' )"
    else
        laststatus=0
    fi
    if [ $lasterror -eq 1 ] && [ $error -eq 0 ]
    then
        send=1
    elif [ "$laststatus" != "$error" ]
    then
        send=1
        echo "Status changed from $error to $laststatus."
        echo $error > /tmp/laststatus
    elif [ $lasterror -eq 0 ] && [ $error -ge 1 ]
    then
        echo "$error_msg" > /tmp/lasterror2
        send=1
    fi
}


## execute_checks(): error
execute_checks()
{
    #little remainder
    #error it's a variable containing the error codes returned by the scripts
    #error_msg is the message returned by the scripts
    #send 1 if there is some mail to send (aka the state changed, error -> solved, solved -> error)
    #/tmp/lasterror2 is the las error message
    #/tmp/lasstatus is the last status
    ######### MAIN ############
    i=1
    for check in $(ls $homedir/checks/*.sh)
    do
        if [ -x $check ]
        then
            error_msg="$error_msg\n$($check)"
            error=$(( $error + $?*$i ))
        fi
        i=$(( $i*10 ))
    done
    return $error
}

## execute_checks() : error
execute_checks
## check_lasterror(error): send
check_lasterror $error
if [ $send -eq 1 ]
then
    #if there's no error, set the apropiate message
    if [ $error -ge 1 ]; then echo "New error, sending mail"
    else echo "Error solved, sending mail"
        error_msg="Errors solved, you can go to sleep now XD \n$error_msg\n\nLast error_msg:$(cat /tmp/lasterror2)"
        rm /tmp/lasterror2
    fi
    send_mail
#if theres no state change but there are still errors, just do nothing
elif [ $error -ge 1 ]
then
    echo "Still got error"
else
    echo "OK $error"
fi

