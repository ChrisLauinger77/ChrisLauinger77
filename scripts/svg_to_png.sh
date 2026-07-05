#/bin/bash


inkscape $1 --export-type="png" -o mac16.png -h 16
inkscape $1 --export-type="png" -o mac32.png -h 32
inkscape $1 --export-type="png" -o mac64.png -h 64
inkscape $1 --export-type="png" -o mac128.png -h 128
inkscape $1 --export-type="png" -o mac256.png -h 256
inkscape $1 --export-type="png" -o mac512.png -h 512
inkscape $1 --export-type="png" -o mac1024.png -h 1024

