#!/bin/bash

running=""
running=`ps -C $1 | grep -v PID`

if [ -n $running ]; then
    echo "$1 is not running"
#    echo "$SERVICE is not running!" | mail -s "$SERVICE down" root
else
    echo "$1 service running, everything is fine"
fi
