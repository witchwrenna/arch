#!/usr/bin/env bash

curl -LO https://github.com/witchwrenna/arch/archive/master.zip
pacman -Sy unzip --noconfirm --needed
unzip -o ~/master.zip
sh arch-main/installarch.sh

#Copy over scripts to prepare for chroot
mv arch-main/configgit.sh /mnt/configgit.sh
mv arch-main/installgit.sh /mnt/installgit.sh

#Customize the OS!
arch-chroot /mnt sh configarch.sh

#Copying over basic config stuff needed for nvidia support
mkdir -p /mnt/home/lilith/.config/hypr/
mv arch-main/config/hyprland.conf /mnt/home/lilith/.config/hypr/hyprland.conf

#Get dotfiles sync support up
arch-chroot /mnt sh /configgit.sh