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
#arch-chroot /mnt sh /configgit.sh

# clean up after done
# rm /mnt/configgit.sh
# rm /mnt/configarch.sh

# todo: 
# Git script does not apply alias and config changes because of chroot?
# Rice zsh
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
# spaceship?;''''''''''
# install nerd fonts? ttf-firacode-nerd as example
# set font for kitty
# fzf - ctrl + r search
# get all those dotfiles working
# install gh for authentication
# then do gh auth setup-git

