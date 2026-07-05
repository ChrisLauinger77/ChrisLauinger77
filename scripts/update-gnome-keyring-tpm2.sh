#!/bin/bash

echo "Enter password"
read password
sudo -u tss /usr/bin/clevis-encrypt-tpm2 '{"pcr_ids":"7","pcr_bank":"sha256"}' <<<$password > ~/.config/gnome-keyring.tpm2
#sudo -u tss /usr/bin/clevis-encrypt-tpm2 '{}' <<<$password > ~/.config/gnome-keyring.tpm2

