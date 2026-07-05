#!/bin/bash

installed=`gnome-extensions list | grep $1`
#echo "$installed xxx"
enabled=`gnome-extensions list --enabled | grep $1`
if [ "$installed" != "$1" ];
then
    notify-send "Extension is not installed" "$1"
    exit 0
fi

if [ "$enabled" = "$1" ];
then
    notify-send --hint=int:transient:1 "Disabled extension" "$1"
    `gnome-extensions disable $1`
else
    notify-send --hint=int:transient:1 "Enabled extension" "$1"
    `gnome-extensions enable $1`
fi
