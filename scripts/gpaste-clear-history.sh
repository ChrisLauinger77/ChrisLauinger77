#!/bin/bash

echo "Delete image history .local/share/gpaste/images/*"
rm ~/.local/share/gpaste/images/*
echo "gpaste-client delete-history"
gpaste-client delete-history
notify-send --hint=int:transient:1 "gpaste-client delete-history"
echo "Done"
