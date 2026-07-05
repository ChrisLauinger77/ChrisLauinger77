#!/bin/bash

ffmpeg -i $1 -r 25 -b $3 $2
