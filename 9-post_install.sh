#!/usr/bin/env bash

echo -e "\nFINAL SETUP AND CONFIGURATION"

echo -e "\nCopy config files"
cp -r configs/. ~/

# set password for sudo
sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
