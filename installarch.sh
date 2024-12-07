#!/usr/bin/env bash

diskid=$1
efi=$2
root=$3

# BIG FUCKING WARNING
#Partitions are hard coded to my 4TB nvme drive in main.sh!!!!!!!!!!! REPLACE THAT IF USING A DIFFERENT DRIVE

echo -e "\nPartitions are hard coded to my 4TB nvme drive!!!!!!!!!!!
echo -e "\nIf you didn't manually format your drive and create your partitions and update the script variables, you HAVE to do this now or this script will fail"
echo -e "\nCheck the script comments and understand what it's doing."
echo -e "\nThis is NOT a general installation script, it is hard coded to my computer and preferences"
echo -e "\nUpdate main.sh with the right variables if you don't wanna do something fucky"
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



#Unmount if already mounted (eg runnning script twice)
swapoff /mnt/swap/swapfile
umount /mnt/boot/efi
umount /mnt

mkfs.vfat -F32 -n "EFI" "${efi}"
mkfs.btrfs -L "Root" -f "${root}"

#get started creating btrfs subvolumes
mount "${root}" /mnt

#Set up btrfs subvolumes
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@var_log
btrfs subvolume create /mnt/@var_cache

umount /mnt

#need to mount root volume
#options:
# noatime stops reading metadata all the time, increases speed
# compression to save space
# space cache improves more performance to know where are free blocks
mount -o noatime,ssd,space_cache=v2,compress=zstd,discard=async,subvol=@ "${root}" /mnt

mkdir -p /mnt/home /mnt/.snapshots /mnt/var/log /mnt/var/cache
mount -o noatime,ssd,space_cache=v2,compress=zstd,discard=async,subvol=@home "${root}" /mnt/home
mount -o noatime,ssd,space_cache=v2,compress=zstd,discard=async,subvol=@snapshots "${root}" /mnt/snapshots
mount -o noatime,ssd,space_cache=v2,compress=zstd,discard=async,subvol=@var_log "${root}" /mnt/var/log
mount -o noatime,ssd,space_cache=v2,compress=zstd,discard=async,subvol=@var_cache "${root}" /mnt/var/cache

# The idea is to mount the EFI partition to /boot/efi directory
# in this way /boot still use btrfs filesystem and /boot/efi use vfat filesystem,
# kernels are stored in /boot and are included in the snapshots
# so no problems with the restores because kernel, libraries and all the system are always "synchronized" 
# mount target
mkdir -p /mnt/boot/efi
mount -t vfat "${efi}" /mnt/boot/efi

echo -e "\nCreating Swap File\n"

btrfs subvolume create /mnt/swap
btrfs filesystem mkswapfile --size 16g --uuid clear /mnt/swap/swapfile
swapon /mnt/swap/swapfile

#read -p "filesystem done (enter)"

#Let's enable parallel downloads :3
sed -i 's/#ParallelDownloads.*/ParallelDownloads=10/' /etc/pacman.conf

echo "--------------------------------------"
echo "-- INSTALLING Arch Linux on Main Drive --"
echo "--------------------------------------"
pacstrap -K /mnt base linux linux-firmware linux-headers intel-ucode btrfs-progs git zsh sudo --noconfirm --needed

#read -p "Main install done (enter)"



# Save current mount configuration
genfstab -U /mnt >> /mnt/etc/fstab

cat /mnt/etc/fstab

#Creating the /etc/resolv.conf symlink will not be possible while inside arch-chroot,
#the file is bind-mounted from the outside system.
#Instead, create the symlink from outside the chroot. E.g. 
ln -sf ../run/systemd/resolve/stub-resolv.conf /mnt/etc/resolv.conf
