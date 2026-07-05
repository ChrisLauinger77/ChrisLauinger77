#!/bin/bash

# List of extension IDs to install
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
  "shortcuts-gnome-extension"
)

for EXT in "${EXTENSIONS[@]}"; do
  echo "Packing $EXT ..."
  cd $source_dir$EXT
  if [[ "$EXT" == "shortcuts-gnome-extension" ]]; then
    cmd="${EXT%%-*}"
    cmd="${cmd,,}"$cmdext  # convert to lowercase & add extension
  else
    cmd="${EXT##*-}"
    cmd="${cmd,,}"$cmdext  # convert to lowercase & add extension
  fi
  $source_dir$EXT/$cmd
  mv $source_dir$EXT/*-extension.zip ~/Downloads/
done



echo "All extensions packed and moved to Downloads folder."