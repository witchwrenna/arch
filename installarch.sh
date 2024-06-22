#!/usr/bin/env bash

#TO Do: automatic snapshots on btrfs??

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

mkfs.vfat -F32 -n "EFI" "${EFI}"
mkfs.btrfs -L "Root" "${ROOT}" -f

# The "trick" is to mount the EFI partition to /boot/efi directory
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
sed '/ParallelDownloads/s/^#//g' -o /etc/pacman.conf

echo "--------------------------------------"
echo "-- INSTALLING Arch Linux on Main Drive --"
echo "--------------------------------------"
pacstrap -K /mnt base linux linux-firmware linux-headers intel-ucode btrfs-progs   --noconfirm --needed

#read -p "Main install done (enter)"

echo "--------------------------------------"
echo "-- Installing the important stuff --"
echo "--------------------------------------"

pacstrap -K /mnt hyfetch man htop git sudo neovim nano zsh firefox less --noconfirm --needed

# Save current mount configuration
genfstab -U /mnt >> /mnt/etc/fstab

cat /mnt/etc/fstab

#read -p "fstab done please check output(enter)"

#Update /etc/default/useradd config to point to /bin/zsh

cat <<REALEND > /mnt/next.sh
groupadd witches
useradd -m -g witches -s /bin/zsh lilith
usermod -aG wheel,storage,audio,video lilith
echo lilith:lilith | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

#Let's enable parallel downloads :3
sed '/ParallelDownloads/s/^#//g' -o /etc/pacman.conf

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
echo "Setting up Networking (need to fix)"
echo "-------------------------------------------------"

cat <<EOF > /etc/systemd/network/20-ethernet.network
[Match]
Name=en*
Name=eth*

[Link]
RequiredForOnline=routable

[Network]
Address=192.168.1.10/24
Gateway=192.168.1.1
DNS=1.1.1.1
EOF

#set up home domain
#following https://www.rfc-editor.org/rfc/rfc8375.html
resolvectl domain eth0 home.arpa

systemctl start systemd-networkd.service
systemctl start systemd-resolved.service


echo "-------------------------------------------------"
echo "Setting up grub"
echo "-------------------------------------------------"
pacman -S grub efibootmgr dosfstools mtools os-prober --noconfirm --needed
#need to mount windows to see stuff
mount /dev/disk/by-id/nvme-eui.002538592140e412-part4 /mnt/win11
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id="DemonBoot"
sed -i 's/^#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
sed -i '/.*^GRUB_CMDLINE_LINUX_DEFAULT=.*/ c\GRUB_CMDLINE_LINUX_DEFAULT="quiet loglevel=3 nvidia_drm.modeset=1/"' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

echo "-------------------------------------------------"
echo "Installing display Drivers"
echo "-------------------------------------------------"

#Should include nvidia drivers + vulkan + Cuda + OpenCL
#https://wiki.hyprland.org/Nvidia/
pacman -S nvidia nvidia-utils nvidia-settings lib32-nvidia-utils libva-nvidia-driver --noconfirm --needed

echo "-------------------------------------------------"
echo "Installing wayland + hyprland"
echo "-------------------------------------------------"

#Following https://wiki.hyprland.org/Nvidia/
pacman -S egl-wayland hyprland sddm --noconfirm --needed
sed -i 's/^MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
mkinitcpio -P
#Check for errors of missing nvidia headers or whatever after mkinicpio

sed -i 'N;/ENVIRONMENT VARIABLES/a\\nenv = NVD_BACKEND,direct\nenv = LIBVA_DRIVER_NAME,nvidia\nenv = XDG_SESSION_TYPE,wayland\nenv = GBM_BACKEND,nvidia-drm\nenv = __GLX_VENDOR_LIBRARY_NAME,nvidia' ~/.config/hypr/hyprland.conf
sed -i '/env = __GLX_VENDOR_LIBRARY_NAME,nvidia/a\\ncursor {\n    no_hardware_cursors = true\n}' ~/.config/hypr/hyprland.conf

systemctl enable sddm.service

echo "-------------------------------------------------"
echo "Setting up audio"
echo "-------------------------------------------------"

pacman -S pipewire pipewire-audio pipewire-pulse wireplumber --noconfirm --needed
systemctl --user enable pipewire pipewire-pulse wireplumber

echo "-------------------------------------------------"
echo "Install Complete, You can reboot now"
echo "-------------------------------------------------"

REALEND

cat <<GIT > /mnt/git.sh

echo "-------------------------------------------------"
echo "Setup git and dotfiles"
echo "-------------------------------------------------"

mkdir $HOME/dotfiles

git config --global user.name "Witch Wrenna"
git config --global user.email witchwrenna@gmail.com

git init --bare $HOME/dotfiles
alias dotfiles='/usr/bin/git --git-dir=$HOME/dotfiles/ --work-tree=$HOME' >> $HOME/.zshrc
source $HOME/.zshrc
dotfiles config --local status.showUntrackedFiles no

#To add stuff...
#dotfiles add $Filename
#dotfiles comment -m "Updating file!"
#dotfiles push

GIT


arch-chroot /mnt sh next.sh



# How do i set those parameters for the nvidia_drm module? It's not exactly clear on that. It does link to another kernel module page, but there it says i need to make a file in /etc/modprobe.d/myfilename.conf (i assume naming it nvidia.conf) with options module_name parameter_name=parameter_value.

# If i understood this correctly, i make a file named nvidia.conf in /etc/modprobe.d/ and in that file i write:

# options nvidia_drm modeset=1 fbdev=1 

# todo: 
# https://wiki.archlinux.org/title/systemd-networkd
# pipeware
# nvidia
# wayland+hyprland
# need a login manager
# set up plymouth
# look at RICING stuff
# Plymouth?
# https://wiki.archlinux.org/title/Category:Eye_candy
# https://github.com/fosslife/awesome-ricing
# plans: pipewire, wayland, hyprland
# More Todo:
# systemd-networkd config
# set default terminal to zsh
# Set alias for new programs (bat, fs, eza)
#Timeshift on btrfs with grub-btrfs can't be beat for snappyshots :3