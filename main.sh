#!/usr/bin/env bash

curl -LO https://github.com/witchwrenna/arch/archive/master.zip
pacman -Sy unzip --noconfirm --needed
unzip ~/master.zip
cd arch-main


#commenting out to avoid accidently running before it's all ready

sh installarch.sh
arch-chroot /mnt /configarch.sh
mkdir -p /mnt/home/lilith/.config/hypr/
mv /config/hyprland.conf /mnt/home/lilith/.config/hypr/hyprland.conf
#arch-chroot /mnt /installgit.sh