#!/bin/bash

backupdir="/tmp/backup"

mkdir $backupdir
mount -t nfs 192.168.22.2:/volume1/backup $backupdir

rsync -vzr --progress --delete --exclude-from '/usr/scripts/exclude.txt' /home/christian/ $backupdir/debian/home/christian
#rsync -vaz --progress --delete --exclude-from '/usr/scripts/exclude.txt' /usr/scripts/ $backupdir/debian/usr/scripts
tar cvzf $backupdir/debian/etc.tar.gz /etc/
tar cvzf $backupdir/debian/usr_scripts.tar.gz /usr/scripts/
#tar cvzf $backupdir/debian/root.tar.gz /root/
umount $backupdir
