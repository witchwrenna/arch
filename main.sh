#!/usr/bin/env bash

curl -LO https://github.com/witchwrenna/arch/archive/master.zip
pacman -Sy unzip --noconfirm --needed
unzip ~/master.zip
cd arch-main
#sh installarch.sh

#Copy over scripts to prepare for chroot
mv configarch.sh /mnt/configarch.sh
mv installgit.sh /mnt/installgit.sh

#Customize the OS!
arch-chroot /mnt sh configarch.sh

#Copying over basic config stuff needed for nvidia support
mkdir -p /mnt/home/lilith/.config/hypr/
mv /config/hyprland.conf /mnt/home/lilith/.config/hypr/hyprland.conf

#Get dotfiles sync support up
arch-chroot /mnt sh /installgit.sh