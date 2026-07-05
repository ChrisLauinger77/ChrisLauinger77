#!/bin/bash

usbbackupdir="/mnt/@usb/sde1"
nasbackupdir="/volume1/backup"

echo "Starting backup to USB-HDD"
echo "Syncing server HDD to USB-HDD ..."
rsync -vaz --exclude-from '/usr/scripts/exclude.txt' --delete /share/CACHEDEV2_DATA/musik/ $usbbackupdir/musik
rsync -vaz --exclude-from '/usr/scripts/exclude.txt' --delete /share/CACHEDEV2_DATA/fotos/ $usbbackupdir/fotos
rsync -vaz --exclude-from '/usr/scripts/exclude.txt' --delete /share/CACHEDEV2_DATA/xxx/ $usbbackupdir/xxx-filme


rsync -vaz --exclude-from '/usr/scripts/exclude.txt' --delete $nasbackupdir/debian/usr_scripts.tar.gz $usbbackupdir/+++backup+++
rsync -vaz --exclude-from '/usr/scripts/exclude.txt' --delete $nasbackupdir/debian/etc.tar.gz $usbbackupdir/+++backup+++

rsync -vaz --exclude-from '/usr/scripts/exclude.txt' --delete $nasbackupdir/debian/home/ $usbbackupdir/+++backup+++/home


echo "Unmounting usb-HDD ..."
umount $usbbackupdir
echo "Done."
