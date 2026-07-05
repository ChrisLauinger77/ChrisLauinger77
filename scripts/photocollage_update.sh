#!/bin/bash

sudo cp /var/data/dev/PhotoCollage/photocollage/gtkgui.py /usr/lib/python3/dist-packages/photocollage/gtkgui.py
msgfmt -o /tmp/de.mo /var/data/dev/PhotoCollage/po/de.po
sudo cp /tmp/de.mo /usr/share/locale/de/LC_MESSAGES/photocollage.mo