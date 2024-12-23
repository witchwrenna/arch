#!/usr/bin/env bash

#Script entry point
#I recommend modifying the variables before running anything or it will try to do hard drive modifications

curl -LO https://github.com/witchwrenna/arch/archive/master.zip
pacman-key --init
pacman -Sy unzip --noconfirm --needed
unzip -o ~/master.zip

#settings variables. Modify these if your environment is different
user="lilith"
group="witches"

diskid="/dev/disk/by-id/nvme-eui.002538414143a0a5"
efi="/dev/disk/by-id/nvme-eui.002538414143a0a5-part1"
root="/dev/disk/by-id/nvme-eui.002538414143a0a5-part2"

#Disk setup and main kernal install
sh arch-main/installarch.sh $diskid $efi $root

#Copying over basic config stuff needed for nvidia support + postinstall run
mkdir -p /mnt/home/$user/.config/hypr/
mv arch-main/config/hyprland.conf /mnt/home/$user/.config/hypr/hyprland.conf

#Let's get chroot going to configure arch my way
mv arch-main/configarch.sh /mnt/configarch.sh 
#put this here to run on first boot through hyprland.conf
# will download dot files
mv arch-main/postinstall.sh /mnt/home/$user/postinstall.sh
#My current pacman conf
mv arch-main/config/pacman.conf /mnt/etc/pacman.conf

arch-chroot /mnt sh configarch.sh $diskid $efi $root $user $group


# Timeshift on btrfs with grub-btrfs can't be beat for snappyshots :3
# visual studio code?
# set font for kitty - partially done still need to look into it
# install gh for authentication
# then do gh auth setup-git
# screensaver??
# sddm rice
# setup keyboard volume knob

#example of firefox config
# https://github.com/sameemul-haque/dotfiles/tree/mocha/.whiteSur-firefox-theme

# try this theme lol
# https://github.com/Naezr/ShyFox/blob/main/showcase.md

#swap caps lock key in hyprland

#resolvd symblink didn't work - busy??
# ln: failed to create symbolic link '/etc/resolv.conf': Device or resource busy

#chown doesn't seem to work?
#ZSH colour variables are black??
