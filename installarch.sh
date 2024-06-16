#!/usr/bin/env bash

#TO Do: automatic snapshots on btrfs??

# BIG FUCKING WARNING
#Partitions are hard coded to my 4TB nvme drive!!!!!!!!!!! REPLACE THAT IF USING A DIFFERENT DRIVE
echo -e "Partitions are hard coded to my 4TB nvme drive!!!!!!!!!!! REPLACE THAT IF USING A DIFFERENT DRIVE"
read -p "Press enter to continue"

# disable secureboot for dualbooting?
# Not sure how to check what device is going to be what
# FUCK I NEED TO LEARN ABOUT LVM
#BTRFS on LVM???

setfont ter-132n

echo -e "\nSetting local keys..\n"
loadkeys us

#If 64, then UEFI mod. If 32, then 32-bit which is weird. Should be 64. Terminate if 32?
echo -e "\nDisplaying boot mode..."
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

read -p "If you didn't manually format your drive, create your partitions, and set the script variables, you HAVE to do this now or this script will fail"


# Okay the final idea is...
# One UEFI system partition 800MB
# Start small, don't overthink. 1TB for root. Figure out where to put the rest later
# No experience means I don't know what is going to take up space! So don't allocate everything immediately

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

mkfs.vfat -F32 -n "EFI" "${EFI}"
mkfs.btrfs -L "Root" "${ROOT}" -f

echo -e "\nCreating Swap File\n"



# mount target
mount "${ROOT}" /mnt
mkdir /mnt/boot
mount -t vfat "${EFI}" /mnt/boot/
swapon "${SWAP}"

btrfs subvolume create /mnt/swap
btrfs filesystem mkswapfile --size 4g --uuid clear /mnt/swap/swapfile
swapon /mnt/swap/swapfile

read -p "filesystem done (enter)"

echo "--------------------------------------"
echo "-- INSTALLING Arch Linux on Main Drive --"
echo "--------------------------------------"
pacstrap -K /mnt base linux linux-firmware intel-ucode  --noconfirm --needed

read -p "Main install done (enter)"

echo "--------------------------------------"
echo "-- Installing the important stuff               --"
echo "--------------------------------------"

pacstrap -K /mnt hyfetch htop git sudo nvim nano zsh --noconfirm --needed

# Save current mount configuration
genfstab -U /mnt >> /mnt/etc/fstab

cat /mnt/etc/fstab

read -p "\nfstab done please check output(enter)"

#LOOK INTO THIS FOR BTRFS https://wiki.archlinux.org/title/Chroot#Using_arch-chroot
#Timeshift on btrfs with grub-btrfs can't be beat for snappyshots :3

cat <<REALEND > /mnt/next.sh
useradd -m -g witches -s /bin/zsh lilith
usermod -aG wheel,storage,audio,video lilith
echo lilith:lilith | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

echo "-------------------------------------------------"
echo "Setup Language to US and set locale"
echo "-------------------------------------------------"
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf

ln -sf /usr/share/zoneinfo/US/Eastern /etc/localtime
hwclock --systohc

echo "-------------------------------------------------"
echo "Setting up network loopback"
echo "-------------------------------------------------"
echo "slut" > /etc/hostname
cat <<EOF > /etc/hosts
127.0.0.1	localhost
::1			localhost
127.0.1.1	slut.localdomain	slut
EOF

echo "-------------------------------------------------"
echo "Setting up grub"
echo "-------------------------------------------------"
pacman -S grub efibootmgr dosfstools mtools os-prober --noconfirm --needed
grub-install --target=x86-64-efi --efi-directory=/boot --bootloader-id="Multiboot"
sed -i 's/^#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

echo "-------------------------------------------------"
echo "Display and Audio Drivers NOT DONE"
echo "-------------------------------------------------"

#Should include nvidia drivers + vulkan + Cuda + OpenCL
pacman -S nvidia nvidia-utils nvidia-settings --noconfirm --needed

#plans: pipewire, wayland, hyprland
#More Todo:
#systemd-networkd config
#nvidia drivers


#Figure out how to use the systemd network thing instead of networkmanager? idk which is better
#Do i need the bluetooth stack if I'm using USB bluetooth??

systemctl --user enable pipewire pipewire-pulse
# systemctl enable NetworkManager bluetooth

echo "-------------------------------------------------"
echo "Install Complete, You can reboot now"
echo "-------------------------------------------------"

REALEND


arch-chroot /mnt sh next.sh


# How do i do that exactly? Some youtube guides mention editing /etc/mkinitcpio.conf and adding nvidia_drm there, but what does "set modeset and fbdev FOR nvidia_drm" mean?

# How do i set those parameters for the nvidia_drm module? It's not exactly clear on that. It does link to another kernel module page, but there it says i need to make a file in /etc/modprobe.d/myfilename.conf (i assume naming it nvidia.conf) with options module_name parameter_name=parameter_value.

# If i understood this correctly, i make a file named nvidia.conf in /etc/modprobe.d/ and in that file i write:

# options nvidia_drm modeset=1 fbdev=1 
