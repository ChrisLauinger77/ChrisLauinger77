#!/bin/bash

OUTPUTPATH=${2:-.}

echo "Using path: $OUTPUTPATH"

if [[ "$1" == "backup" ]]; then
    echo "Backup mode selected"
    dpkg --get-selections | grep -v deinstall | awk '{print $1}' > $OUTPUTPATH/package.lst
fi
if [[ "$1" == "restore" ]]; then
    echo "Restore mode selected"
    if [[ -f package.lst ]]; then
        dpkg --set-selections < $OUTPUTPATH/package.lst
        apt-get -y update
        apt-get -y install $(cat $OUTPUTPATH/package.lst)
        # aptitude install -y $(cat package.lst)
    else
        echo "Error: $OUTPUTPATH/package.lst not found. Please run backup first."
        exit 1
    fi
fi