#!/usr/bin/env bash
FILENAME="Nextcloud.Talk-linux-x64.flatpak"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

echo Saving File to ${TMPDIR}
wget -q -P ${TMPDIR} --timestamping --continue https://github.com/nextcloud-releases/talk-desktop/releases/latest/download/${FILENAME}
/usr/bin/flatpak kill com.nextcloud.talk
sudo /usr/bin/flatpak install -y  ${TMPDIR}/${FILENAME} && echo Done Install of ${FILENAME}
