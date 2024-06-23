#!/usr/bin/env bash

# BIG FUCKING WARNING
#Partitions are hard coded to my 4TB nvme drive!!!!!!!!!!! REPLACE THAT IF USING A DIFFERENT DRIVE

echo -e "Partitions are hard coded to my 4TB nvme drive!!!!!!!!!!! IF YOU ARE NOT WREN THEN YOU NEED TO UPDATE THE SCRIPT"
echo -e "\nIf you didn't manually format your drive and create your partitions and update the script variables, you HAVE to do this now or this script will fail"
echo -e "\nCheck the script comments and understand what it's doing."
echo -e "\nThis is NOT a general installation script, it is hard coded to my computer and preferences"
read -p "Press enter if you think everything is good!"

# disable secureboot for dualbooting?
# Not sure how to check what device is going to be what
# FUCK I NEED TO LEARN ABOUT LVM
#BTRFS on LVM???

setfont ter-132n

echo -e "\nSetting local keys..\n"
loadkeys us

#If 64, then UEFI mod. If 32, then 32-bit which is weird. Should be 64. Terminate if 32?
echo -e "\nDisplaying boot mode...make sure it's 64"
cat /sys/firmware/efi/fw_platform_size

echo -e "\n\nDisplaying network...\n"
ip link

#echo -e "\nConfirm adding 192.168.1.10 to eth0?\n"
#read -p "Press enter if yes"

#ip address add 192.168.1.10/24 dev eth0
#ip route add default via 192.168.1.1 dev eth0

timedatectl set-timezone EST

# make filesystems
echo -e "\nCreating Filesystems...\nactually you gotta do this yourself, loser\n"

#lsblk --output=NAME,SIZE,VENDOR,MODEL,SERIAL,WWN

#ls -l /dev/disk/by-id

#Scripting with sfdisk is annoying so this will be manual
#Run these commands:
#lsblk to check disk
#cfdisk /dev/nvme
#then make the EFI, general partition
#Set the type correctly!!!!!!!

#ZRAM over ZSwap?
# One person says On systems that are starved for RAM, use zswap with a traditional swap device.

#This section is hardcoded. NEED to change if using different drives.

echo -e "\nSettings filesystem to BTRFS\n"

EFI="/dev/disk/by-id/nvme-eui.002538414143a0a5-part1"
ROOT="/dev/disk/by-id/nvme-eui.002538414143a0a5-part2"

#Unmount if already mounted (eg runnning script twice)
swapoff /mnt/swap/swapfile
umount /mnt/boot/efi
umount /mnt

mkfs.vfat -F32 -n "EFI" "${EFI}"
mkfs.btrfs -L "Root" -f "${ROOT}"

# The idea is to mount the EFI partition to /boot/efi directory
# in this way /boot still use btrfs filesystem and /boot/efi use vfat filesystem,
# kernels are stored in /boot and are included in the snapshots
# so no problems with the restores because kernel, libraries and all the system are always "synchronized" 
# mount target
mount "${ROOT}" /mnt
mkdir /mnt/boot
mkdir /mnt/boot/efi
mount -t vfat "${EFI}" /mnt/boot/efi

echo -e "\nCreating Swap File\n"

btrfs subvolume create /mnt/swap
btrfs filesystem mkswapfile --size 4g --uuid clear /mnt/swap/swapfile
swapon /mnt/swap/swapfile

#read -p "filesystem done (enter)"

#Let's enable parallel downloads :3
sed -i 's/#ParallelDownloads.*/ParallelDownloads=10/' /etc/pacman.conf

echo "--------------------------------------"
echo "-- INSTALLING Arch Linux on Main Drive --"
echo "--------------------------------------"
pacstrap -K /mnt base linux linux-firmware linux-headers intel-ucode btrfs-progs zsh sudo --noconfirm --needed

#read -p "Main install done (enter)"



# Save current mount configuration
genfstab -U /mnt >> /mnt/etc/fstab

cat /mnt/etc/fstab

#read -p "fstab done please check output(enter)"

# todo: 
# Update /etc/default/useradd config to point to /bin/zsh
# verify pipeware
# get wayland+hyprland working (nvidia issues?)
# rice the login manager
# set up plymouth? look into alternatives too
# https://wiki.archlinux.org/title/Category:Eye_candy
# https://github.com/fosslife/awesome-ricing
# Set alias for new programs (bat, fs, eza)
# Timeshift on btrfs with grub-btrfs can't be beat for snappyshots :3
# Figure out best way to copy entire config files