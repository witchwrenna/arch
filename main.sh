#!/usr/bin/env bash

curl -LO https://github.com/witchwrenna/arch/archive/master.zip
pacman -Sy unzip --noconfirm --needed
unzip ~/master.zip
cd arch-main


#Run files
#Move config over

#sh installarch.sh
#mkdir -p /mnt/home/lilith/.config/hypr/
#mv /config/hyprland.conf /mnt/home/lilith/.config/hypr/hyprland.conf
#arch-chroot /mnt /configarch.sh
#arch-chroot /mnt /installgit.sh