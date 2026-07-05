#!/bin/bash

#if [ ! -z "$1" ]
#  then
    cd $1
#fi

if [ -z "$2" ]
  then
    ext_from="webp"
  else
    ext_from="$2"
fi

if [ -z "$3" ]
  then
    ext_to="png"
  else
    ext_to="$3"
fi

echo "Convert from: '$ext_from' to  '$ext_to'"

for x in `ls -1 *."$ext_from"`; do dwebp {} -o ${x%.*}."$ext_to" ::: $x; done

