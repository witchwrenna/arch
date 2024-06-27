#!/usr/bin/env bash
curl -LO https://github.com/witchwrenna/arch/archive/master.zip
pacman -Sy unzip --noconfirm --needed
unzip -o ~/master.zip

#settings variables. Modify these if your environment is different
user="lilith"
group="witches"

diskid="/dev/disk/by-id/nvme-eui.002538414143a0a5"
efi="/dev/disk/by-id/nvme-eui.002538414143a0a5-part1"
root="/dev/disk/by-id/nvme-eui.002538414143a0a5-part2"

sh arch-main/installarch.sh $diskid $efi $root

#Let's get chroot going
mv arch-main/configarch.sh /mnt/configarch.sh 
arch-chroot /mnt sh configarch.sh $diskid $efi $root $user $group

#This stuff will run on first boot
mv arch-main/postinstall.sh /mnt/home/$user/postinstall.sh

#Copying over basic config stuff needed for nvidia support
mkdir -p /mnt/home/$user/.config/hypr/
mv arch-main/config/hyprland.conf /mnt/home/$user/.config/hypr/hyprland.conf

mkdir -p /mnt/boot/efi/EFI/refind/
mv arch-main/config/refind.conf /mnt/boot/efi/EFI/refind/refind.conf

# Get dotfiles sync support up
# disabling because needs to be run as user?
# arch-chroot /mnt sh /postinstall.sh

# clean up after done or the files stay after booting
# rm /mnt/postinstall.sh

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

# try this theme lol
# https://github.com/Naezr/ShyFox/blob/main/showcase.md

#more dots to check out
# https://github.com/Naezr/ShyFox/blob/main/showcase.md
# 

#swap caps lock key in hyprland

#resolvd symblink didn't work - busy??
# ln: failed to create symbolic link '/etc/resolv.conf': Device or resource busy

#chown doesn't seem to work?
#maybe add postinstall to exec-once for hyprland, and then include rm-ing itself and removing the line
#ZSH colour variables are black??