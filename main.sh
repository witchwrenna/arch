#!/usr/bin/env bash

curl -LO https://github.com/witchwrenna/arch/archive/master.zip
pacman -Sy unzip --noconfirm --needed
unzip -o ~/master.zip
sh arch-main/installarch.sh

#Copy over scripts to prepare for chroot
mv arch-main/configgit.sh /mnt/configgit.sh
mv arch-main/configarch.sh /mnt/configarch.sh

#Customize the OS!
arch-chroot /mnt sh configarch.sh

#Copying over basic config stuff needed for nvidia support
mkdir -p /mnt/home/lilith/.config/hypr/
mv arch-main/config/hyprland.conf /mnt/home/lilith/.config/hypr/hyprland.conf

#Get dotfiles sync support up
#disabling because needs to be run as user
#arch-chroot /mnt sh /configgit.sh


#TBD... arch chroot sets wrong user permissions when in home file
#Git script does not apply alias to zsh