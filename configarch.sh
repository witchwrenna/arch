#!/usr/bin/env bash

groupadd witches
useradd -m -g witches -s /bin/zsh lilith
usermod -aG wheel,storage,audio,video lilith
echo lilith:lilith | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

#Let's enable parallel downloads :3
sed -i '/ParallelDownloads/s/^#//g' /etc/pacman.conf

echo "-------------------------------------------------"
echo "Setup Language to US and set locale"
echo "-------------------------------------------------"
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf

ln -sf /usr/share/zoneinfo/US/Eastern /etc/localtime
hwclock --systohc

# read -p "pausing... press enter to continue"

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
echo "Setting up Networking"
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

sed -i 's/^#Domains=/Domains=home.arpa/' /etc/systemd/resolved.conf

#set up home domain
#following https://www.rfc-editor.org/rfc/rfc8375.html
systemctl enable systemd-networkd.service 
systemctl enable systemd-resolved.service 

# read -p "pausing... press enter to continue"

echo "-------------------------------------------------"
echo "Installing display Drivers"
echo "-------------------------------------------------"

#Should include nvidia drivers + vulkan + Cuda + OpenCL
#https://wiki.hyprland.org/Nvidia/
pacman -S nvidia nvidia-utils nvidia-settings libva-nvidia-driver --noconfirm --needed

# read -p "pausing... press enter to continue"

echo "-------------------------------------------------"
echo "Setting up REFIND"
echo "-------------------------------------------------"
# pacman -S grub efibootmgr dosfstools mtools os-prober --noconfirm --needed
# #need to mount windows to see stuff
# mount /dev/disk/by-id/nvme-eui.002538592140e412-part2 /mnt/win11
# grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id="DemonBoot"
# sed -i 's/^#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
# sed -i '/.*^GRUB_CMDLINE_LINUX_DEFAULT=.*/ c\GRUB_CMDLINE_LINUX_DEFAULT="quiet loglevel=3 nvidia_drm.modeset=1/"' /etc/default/grub
# grub-mkconfig -o /boot/grub/grub.cfg

# read -p "trying out refind press enter"

pacman -S refind efibootmgr --noconfirm --needed

mkdir -p /boot/efi/EFI/refind
cp /usr/share/refind/refind_x64.efi /boot/efi/EFI/refind/
efibootmgr --create --disk /dev/disk/by-id/nvme-eui.002538414143a0a5 --part 1 --loader /EFI/refind/refind_x64.efi --label "DemonBoot" --unicode
cp -r /usr/share/refind/icons /boot/efi/EFI/refind/

#create $UUID from fstab because UUID changes after mkfs
#This is like running . source on the first column containing a UUID
cat /etc/fstab | grep -A1 Root | grep UUID | awk -v col=1 '{print $col}' | source /dev/stdin

echo "grabbed UUID $UUID"
read -p "press enter to continue"

cat <<BOOT > /boot/refind_linux.conf
"Boot using default options"     "root=PARTUUID=$UUID rw loglevel=3 quiet nvidia_drm.modeset=1"
"Boot using fallback initramfs"  "root=PARTUUID=$UUID rw initrd=boot\initramfs-%v-fallback.img"
"Boot to terminal"               "root=PARTUUID=$UUID rw systemd.unit=multi-user.target"
BOOT

cp /usr/share/refind/refind.conf-sample /boot/efi/EFI/refind/refind.conf
sed -i '/extra_kernel_version_strings/s/^#//g' /boot/efi/EFI/refind/refind.conf

cat <<STANZA >> /boot/efi/EFI/refind/refind.conf
menuentry "Arch Linux" {
	icon     /EFI/refind/icons/os_arch.png
	volume   "Arch Linux"
	loader   /boot/vmlinuz-linux
	initrd   /boot/initramfs-linux.img
	options  "root=PARTUUID=$UUID rw loglevel=3 quiet nvidia_drm.modeset=1"
	submenuentry "Boot using fallback initramfs" {
		initrd /boot/initramfs-linux-fallback.img
	}
	submenuentry "Boot to terminal" {
		add_options "systemd.unit=multi-user.target"
	}
}
STANZA

read -p "press enter to continue"

#The default entry is based on the current /proc/cmdline. 
#The default entry is based on the current /proc/cmdline. 
#The default entry is based on the current /proc/cmdline. 
#The default entry is based on the current /proc/cmdline. 
#The default entry is based on the current /proc/cmdline. 
#The default entry is based on the current /proc/cmdline. 

echo "-------------------------------------------------"
echo "Installing wayland + hyprland"
echo "-------------------------------------------------"

#Following https://wiki.hyprland.org/Nvidia/
pacman -S egl-wayland hyprland sddm --noconfirm --needed
sed -i 's/^MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
echo "options nvidia_drm modeset=1 fbdev=1" > /etc/modprobe.d/nvidia.conf
mkinitcpio -P
#Check for errors of missing nvidia headers or whatever after mkinicpio

systemctl enable sddm.service

# read -p "pausing... press enter to continue"

echo "-------------------------------------------------"
echo "Setting up audio"
echo "-------------------------------------------------"

pacman -S pipewire pipewire-audio pipewire-pulse wireplumber --noconfirm --needed
systemctl --user enable pipewire pipewire-pulse wireplumber

# read -p "pausing... press enter to continue"

echo "--------------------------------------"
echo "-- Installing the important stuff --"
echo "--------------------------------------"

pacman -S hyfetch man htop git sudo neovim nano firefox less --noconfirm --needed

echo "-------------------------------------------------"
echo "Install Complete, You can reboot now"
echo "-------------------------------------------------"

