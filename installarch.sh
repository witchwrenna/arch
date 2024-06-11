#!/usr/bin/env bash

#For other users: Check your IP address!

#Current file system ideas:

#Copy 1TB SSD to 2 TB SSD



#Need to add:
#1. swap file/ partition was not created (needed to support RAM and hibernation)
#2. os-prober was not enabled in grub config for dual-booting PCs.
# disable secureboot for dualbooting
# Not sure how to check what device is going to be what
# FUCK I NEED TO LEARN ABOUT LVM
#BTRFS on LVM

echo -e "\nSetting local keys..\n"
loadkeys us

#If 64, then UEFI mod. If 32, then 32-bit which is weird. Should be 64. Terminate if 32?
echo -e "\nChecking boot mode...\n"
UEFI=cat /sys/firmware/efi/fw_platform_size
cat /sys/firmware/efi/fw_platform_size

echo -e "\nConfiguring network...\n"
ip link

echo -e "\nConfirm adding 192.168.1.10 to eth0?\n"
read -p "Press enter if yes"

ip address add 192.168.1.10/24 dev eth0
ip route add default via 192.168.1.1 dev eth0

timedatectl set-timezone EST

#Todo might need to double check what arch does by default

# make filesystems
echo -e "\nCreating Filesystems...\n"

#2 TB NVME for windows
#4TB drive gets split 1TB OS/2TB Home/1TB empty?
#3 TB Hard Drives for the NAS? oR JUST TAKE them out forever
#1 TB SSD FOR GAMES
#2 TB 2 SSDs for GAMES

#No maybe this is too complicated....
#4TB nvme for everything except games?

#/Steam folder!
#Create a 2TB /nonsteam game folder?
#Maybe a 1TB shadowplay drive?
#Maybe.... this is the point of LVM is not having to worry about this.
#/Steam

#NOT READY
lsblk
fdisk /dev/nvme0n1

 nvme id-ns -H /dev/nvme0n1 | grep "Relative Performance"

#Don't forget zdisk? The RAM thingy??

#Okay the final idea is...
#One partition for root, nvme
#One UEFI system partition 1GB

#Gotta figure this shit OUT
mkfs.vfat -F32 -n "EFISYSTEM" "${EFI}"
mkswap "${SWAP}"
swapon "${SWAP}"
mkfs.ext4 -L "ROOT" "${ROOT}"

# mount target
mount -t ext4 "${ROOT}" /mnt
mkdir /mnt/boot
mount -t vfat "${EFI}" /mnt/boot/

echo "--------------------------------------"
echo "-- INSTALLING Arch Linux BASE on Main Drive       --"
echo "--------------------------------------"
pacstrap /mnt base base-devel --noconfirm --needed

# kernel
pacstrap /mnt linux linux-firmware --noconfirm --needed

echo "--------------------------------------"
echo "-- Setup Dependencies               --"
echo "--------------------------------------"

pacstrap /mnt networkmanager network-manager-applet wireless_tools nano intel-ucode bluez bluez-utils blueman git --noconfirm --needed

# fstab
genfstab -U /mnt >> /mnt/etc/fstab

echo "--------------------------------------"
echo "-- Bootloader Installation  --"
echo "--------------------------------------"
bootctl install --path /mnt/boot
echo "default arch.conf" >> /mnt/boot/loader/loader.conf
cat <<EOF > /mnt/boot/loader/entries/arch.conf
title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=${ROOT} rw
EOF


cat <<REALEND > /mnt/next.sh
useradd -m $USER
usermod -aG wheel,storage,power,audio $USER
echo $USER:$PASSWORD | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

echo "-------------------------------------------------"
echo "Setup Language to US and set locale"
echo "-------------------------------------------------"
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf

ln -sf /usr/share/zoneinfo/Asia/Kathmandu /etc/localtime
hwclock --systohc

echo "arch" > /etc/hostname
cat <<EOF > /etc/hosts
127.0.0.1	localhost
::1			localhost
127.0.1.1	arch.localdomain	arch
EOF

echo "-------------------------------------------------"
echo "Display and Audio Drivers"
echo "-------------------------------------------------"

pacman -S xorg pulseaudio --noconfirm --needed

systemctl enable NetworkManager bluetooth

#DESKTOP ENVIRONMENT
if [[ $DESKTOP == '1' ]]
then 
    pacman -S gnome gdm --noconfirm --needed
    systemctl enable gdm
elif [[ $DESKTOP == '2' ]]
then
    pacman -S plasma sddm kde-applications --noconfirm --needed
    systemctl enable sddm
elif [[ $DESKTOP == '3' ]]
then
    pacman -S xfce4 xfce4-goodies lightdm lightdm-gtk-greeter --noconfirm --needed
    systemctl enable lightdm
else
    echo "You have choosen to Install Desktop Yourself"
fi

echo "-------------------------------------------------"
echo "Install Complete, You can reboot now"
echo "-------------------------------------------------"

REALEND


arch-chroot /mnt sh next.sh