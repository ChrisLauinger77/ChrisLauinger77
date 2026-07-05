#!/bin/bash

function unpack() {
echo "unpack Parameter #1 is $1"
if [[ -z "$1" ]]; then
    echo "unpack: file cannot be empty"
    exit
fi

if [[ -z "$2" ]]; then
    tmp="tmp"
else
    tmp=$2
fi
    dpkg-deb -R $1 $tmp
}


function pack() {
echo "pack Parameter #1 is $1"
if [[ -z "$1" ]]; then
    echo "pack: file cannot be empty"
    exit
fi

if [[ -z "$2" ]]; then
    tmp="tmp"
else
    tmp=$2
fi

dpkg-deb -b $tmp $1
rm $tmp -R
}

function usage() {
    echo 'Useage: ./deb-packaging.sh COMMAND file.deb foldername'
    echo 'COMMAND:'
    echo "  unpack  unpack the deb to foldername"
    echo '  pack    build the file.deb from foldername'
}

case "$1" in
    "unpack" )
        unpack $2 $3
        ;;

    "pack" )
        pack $2 $3
        ;;

    * )
        usage
        ;;
esac
exit
