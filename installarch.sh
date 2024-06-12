#!/usr/bin/env bash

#For other users: Check your IP address!
# BIG FUCKING WARNING
#Partitions are hard coded to my 4TB nvme drive!!!!!!!!!!! REPLACE THAT IF USING A DIFFERENT DRIVE
echo -e "Partitions are hard coded to my 4TB nvme drive!!!!!!!!!!! REPLACE THAT IF USING A DIFFERENT DRIVE"
echo -e "Partitions are hard coded to my 4TB nvme drive!!!!!!!!!!! REPLACE THAT IF USING A DIFFERENT DRIVE"
echo -e "Partitions are hard coded to my 4TB nvme drive!!!!!!!!!!! REPLACE THAT IF USING A DIFFERENT DRIVE"
echo -e "Partitions are hard coded to my 4TB nvme drive!!!!!!!!!!! REPLACE THAT IF USING A DIFFERENT DRIVE"
echo -e "Partitions are hard coded to my 4TB nvme drive!!!!!!!!!!! REPLACE THAT IF USING A DIFFERENT DRIVE"
echo -e "Partitions are hard coded to my 4TB nvme drive!!!!!!!!!!! REPLACE THAT IF USING A DIFFERENT DRIVE"
echo -e "Partitions are hard coded to my 4TB nvme drive!!!!!!!!!!! REPLACE THAT IF USING A DIFFERENT DRIVE"
echo -e "Partitions are hard coded to my 4TB nvme drive!!!!!!!!!!! REPLACE THAT IF USING A DIFFERENT DRIVE"
echo -e "Partitions are hard coded to my 4TB nvme drive!!!!!!!!!!! REPLACE THAT IF USING A DIFFERENT DRIVE"
echo -e "Partitions are hard coded to my 4TB nvme drive!!!!!!!!!!! REPLACE THAT IF USING A DIFFERENT DRIVE"
echo -e "Partitions are hard coded to my 4TB nvme drive!!!!!!!!!!! REPLACE THAT IF USING A DIFFERENT DRIVE"
echo -e "Partitions are hard coded to my 4TB nvme drive!!!!!!!!!!! REPLACE THAT IF USING A DIFFERENT DRIVE"
echo -e "Partitions are hard coded to my 4TB nvme drive!!!!!!!!!!! REPLACE THAT IF USING A DIFFERENT DRIVE"
echo -e "Partitions are hard coded to my 4TB nvme drive!!!!!!!!!!! REPLACE THAT IF USING A DIFFERENT DRIVE"
echo -e "Partitions are hard coded to my 4TB nvme drive!!!!!!!!!!! REPLACE THAT IF USING A DIFFERENT DRIVE"
echo -e "Partitions are hard coded to my 4TB nvme drive!!!!!!!!!!! REPLACE THAT IF USING A DIFFERENT DRIVE"
echo -e "Partitions are hard coded to my 4TB nvme drive!!!!!!!!!!! REPLACE THAT IF USING A DIFFERENT DRIVE"
echo -e "Partitions are hard coded to my 4TB nvme drive!!!!!!!!!!! REPLACE THAT IF USING A DIFFERENT DRIVE"
echo -e "Partitions are hard coded to my 4TB nvme drive!!!!!!!!!!! REPLACE THAT IF USING A DIFFERENT DRIVE"
echo -e "Partitions are hard coded to my 4TB nvme drive!!!!!!!!!!! REPLACE THAT IF USING A DIFFERENT DRIVE"
echo -e "Partitions are hard coded to my 4TB nvme drive!!!!!!!!!!! REPLACE THAT IF USING A DIFFERENT DRIVE"
echo -e "Partitions are hard coded to my 4TB nvme drive!!!!!!!!!!! REPLACE THAT IF USING A DIFFERENT DRIVE"
echo -e "Partitions are hard coded to my 4TB nvme drive!!!!!!!!!!! REPLACE THAT IF USING A DIFFERENT DRIVE"
echo -e "Partitions are hard coded to my 4TB nvme drive!!!!!!!!!!! REPLACE THAT IF USING A DIFFERENT DRIVE"
echo -e "Partitions are hard coded to my 4TB nvme drive!!!!!!!!!!! REPLACE THAT IF USING A DIFFERENT DRIVE"
read -p "Press enter to continue"


#2. os-prober was not enabled in grub config for dual-booting PCs.
# disable secureboot for dualbooting
# Not sure how to check what device is going to be what
# FUCK I NEED TO LEARN ABOUT LVM
#BTRFS on LVM
setfont ter-132n

echo -e "\nSetting local keys..\n"
loadkeys us

#If 64, then UEFI mod. If 32, then 32-bit which is weird. Should be 64. Terminate if 32?
echo -e "\Displaying boot mode..."
cat /sys/firmware/efi/fw_platform_size

echo -e "\Displaying network...\n"
ip link

#echo -e "\nConfirm adding 192.168.1.10 to eth0?\n"
#read -p "Press enter if yes"

#ip address add 192.168.1.10/24 dev eth0
#ip route add default via 192.168.1.1 dev eth0

timedatectl set-timezone EST

# make filesystems
echo -e "\nCreating Filesystems...\nactually you gotta do this yourself, loser\n"

lsblk --output=NAME,SIZE,VENDOR,MODEL,SERIAL,WWN

ls -l /dev/disk/by-id

read -p "If you didn't manually format your drive, create your partitions, and set the script variables, you HAVE to do this now or this script will fail"

#Don't forget zdisk? The RAM thingy??

# Okay the final idea is...
# One UEFI system partition 800MB
# 4GB swap - seems unneccesary if using zram but the internet gives lots of advice with no testing to back it up lol
# Start small, don't overthink. 1TB for root. Figure out where to put the rest later
# No experience means I don't know what is going to take up space! So don't allocate everything immediately

#Scripting with sfdisk is annoying so this will be manual
#Run these commands:
#lsblk to check disk
#cfdisk /dev/nvme
#then make the EFI, swap, general partition
#Set the type correctly!!!!!!!

#ZRAM over ZSwap?
# One person says On systems that are starved for RAM, use zswap with a traditional swap device.

#This section is hardcoded. NEED to change if using different hardware.

EFI="/dev/by-id/nvme-eui.0025384141-part1"
SWAP="/dev/by-id/nvme-eui.0025384141-part2"
ROOT="/dev/by-id/nvme-eui.0025384141-part3"

mkfs.vfat -F32 -n "EFI" "${EFI}"
mkswap "${SWAP}"
mkfs.btrfs -L "Root" "${ROOT}"

# mount target
mount -t ext4 "${ROOT}" /mnt
mkdir /mnt/boot
mount -t vfat "${EFI}" /mnt/boot/
swapon "${SWAP}"

echo "--------------------------------------"
echo "-- INSTALLING Arch Linux BASE on Main Drive --"
echo "--------------------------------------"
pacstrap -K /mnt base linux linux-firmware intel-ucode  --noconfirm --needed

# echo "--------------------------------------"
# echo "-- Setup cool stuff               --"
# echo "--------------------------------------"

pacstrap -K /mnt hyfetch htop git sudo htop nvim nano --noconfirm --needed

# Save current mount configuration
genfstab -U /mnt >> /mnt/etc/fstab


# ----------- EVERYTHING BELOW IS UNTOUCHED FROM ORIGINAL SCRIPT --------------
# ----------- This is as far as I went! ---------------------------------------

# echo "--------------------------------------"
# echo "-- Bootloader Installation  --"
# echo "--------------------------------------"
# bootctl install --path /mnt/boot
# echo "default arch.conf" >> /mnt/boot/loader/loader.conf
# cat <<EOF > /mnt/boot/loader/entries/arch.conf
# title Arch Linux
# linux /vmlinuz-linux
# initrd /initramfs-linux.img
# options root=${ROOT} rw
# EOF


# cat <<REALEND > /mnt/next.sh
# useradd -m $USER
# usermod -aG wheel,storage,power,audio $USER
# echo $USER:$PASSWORD | chpasswd
# sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# echo "-------------------------------------------------"
# echo "Setup Language to US and set locale"
# echo "-------------------------------------------------"
# sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
# locale-gen
# echo "LANG=en_US.UTF-8" >> /etc/locale.conf

# ln -sf /usr/share/zoneinfo/Asia/Kathmandu /etc/localtime
# hwclock --systohc

# echo "arch" > /etc/hostname
# cat <<EOF > /etc/hosts
# 127.0.0.1	localhost
# ::1			localhost
# 127.0.1.1	arch.localdomain	arch
# EOF

# echo "-------------------------------------------------"
# echo "Display and Audio Drivers"
# echo "-------------------------------------------------"

# pacman -S xorg pulseaudio --noconfirm --needed

# systemctl enable NetworkManager bluetooth

# #DESKTOP ENVIRONMENT
# if [[ $DESKTOP == '1' ]]
# then 
#     pacman -S gnome gdm --noconfirm --needed
#     systemctl enable gdm
# elif [[ $DESKTOP == '2' ]]
# then
#     pacman -S plasma sddm kde-applications --noconfirm --needed
#     systemctl enable sddm
# elif [[ $DESKTOP == '3' ]]
# then
#     pacman -S xfce4 xfce4-goodies lightdm lightdm-gtk-greeter --noconfirm --needed
#     systemctl enable lightdm
# else
#     echo "You have choosen to Install Desktop Yourself"
# fi

# echo "-------------------------------------------------"
# echo "Install Complete, You can reboot now"
# echo "-------------------------------------------------"

# REALEND


# arch-chroot /mnt sh next.sh