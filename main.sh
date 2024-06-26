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

#disabling because needs to be run as user?
arch-chroot /mnt sh /configgit.sh

# clean up after done or the files stay after booting
rm /mnt/configgit.sh
rm /mnt/configarch.sh

# todo: 
# Git script does not apply alias and config changes because of chroot?
# rice hyprland
# refind uggly af fix that shit
# Update /etc/default/useradd config to point to /bin/zsh
# sound not working
# set up plymouth? look into alternatives too
# https://wiki.archlinux.org/title/Category:Eye_candy
# https://github.com/fosslife/awesome-ricing
# Set alias for new programs (bat, fs, eza)
# Timeshift on btrfs with grub-btrfs can't be beat for snappyshots :3
# visual studio code?
# slip in main.sh into arch iso?
# set font for kitty - partially done still need to look into it
# install gh for authentication
# then do gh auth setup-git
# set up gsync and correct framerate
# ctrl arrows + home/end doesn't work in zsh?
# configure waybar + all the other hyprland stuff
# screensaver??
# maybe have a base install + additional programs?
# maybe some stuff should be seperate and not part of a base install
# copy paste is fucky
# sddm rice
# setup keyboard volume knob

#example of firefox config
# https://github.com/sameemul-haque/dotfiles/tree/mocha/.whiteSur-firefox-theme