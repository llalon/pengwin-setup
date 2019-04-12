#!/bin/bash

source $(dirname "$0")/common.sh "$@"

if (whiptail --title "POWERSHELL" --yesno "Would you like to download and install Powershell?" 8 55) then
    echo "Installing POWERSHELL"
    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
    sudo cp microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
    rm microsoft.gpg
    sudo sh -c 'echo "deb https://packages.microsoft.com/repos/microsoft-debian-stretch-prod stretch main" > /etc/apt/sources.list.d/microsoft.list'
    sudo sh -c 'echo "deb https://deb.debian.org/debian/ stable main contrib non-free" > /etc/apt/sources.list.d/stable.list'
    sudo sh -c 'echo " " >> /etc/apt/preferences'
    sudo sh -c 'echo "Package: *" >> /etc/apt/preferences'
    sudo sh -c 'echo "Pin: release a=stable" >> /etc/apt/preferences'
    sudo sh -c 'echo "Pin-Priority: 499" >> /etc/apt/preferences'
    sudo apt-get update
    sudo apt-get install powershell -y
else
    echo "Skipping POWERSHELL"
fi
