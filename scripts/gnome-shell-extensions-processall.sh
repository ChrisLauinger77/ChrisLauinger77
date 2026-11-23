#!/bin/bash

# List of extension IDs to process
source_dir="/var/data/dev/"
if [ -z "$1" ]; then
  cmdext=".sh pack"
else
  cmdext=".sh $1"
fi

EXTENSIONS=(
  "gnome-shell-extension-HeadsetControl"
  "gnome-shell-extension-messagingmenu"
  "gnome-shell-extension-SettingsCenter"
  "gnome-shell-extension-SmartAutoMoveNG"
  "gnome-shell-extension-HardDiskLEDNG"
  "gnome-shell-extension-PaseoUsage"
  "shortcuts-gnome-extension"
)

for EXT in "${EXTENSIONS[@]}"; do
  echo "Packing $EXT ..."
  cd $source_dir$EXT
#  npm install
#  npm run lint
  if [[ "$EXT" == "shortcuts-gnome-extension" ]]; then
    cmd="${EXT%%-*}"
    cmd="${cmd,,}"$cmdext  # convert to lowercase & add extension
  else
    cmd="${EXT##*-}"
    cmd="${cmd,,}"$cmdext  # convert to lowercase & add extension
  fi
  $source_dir$EXT/$cmd
  if [[ "$1" == "pack" || "$1" == "" ]]; then
    mv $source_dir$EXT/*-extension.zip ~/Downloads/
  fi
done


if [[ "$1" == "pack" ]]; then
  echo "All extensions packed and moved to Downloads folder."
else
  echo "All extensions processed with $1"
fi
