#!/usr/bin/env bash

#These variables get passed by main. Modify main.sh to change these variables
diskid=$1
efi=$2
root=$3
user=$4
group=$5

echo "-------------------------------------------------"
echo "Setup Storage health"
echo "-------------------------------------------------"

systemctl enable fstrim.timer
systemctl enable btrfs-scrub@-.timer

echo "-------------------------------------------------"
echo "Setup user and group"
echo "-------------------------------------------------"

groupadd $group
sed -i 's|SHELL=.*|SHELL=/usr/bin/zsh|' /etc/default/useradd
useradd -m -g $group -s /bin/zsh $user
usermod -aG wheel,storage,audio,video $user
echo $user:$user | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

echo "-------------------------------------------------"
echo "Setup pacman"
echo "-------------------------------------------------"

pacman -Sy

#Need to finish setting this up
pacman -Sy base-devel reflector --needed --noconfirm #for AUR

systemctl enable reflector.timer

echo "-------------------------------------------------"
echo "Setup Language to US and set locale"
echo "-------------------------------------------------"
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf

ln -sf /usr/share/zoneinfo/US/Eastern /etc/localtime
hwclock --systohc


echo "-------------------------------------------------"
echo "Setting up hostname"
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

#set up home domain
#following https://www.rfc-editor.org/rfc/rfc8375.html
sed -i 's/^#Domains=/Domains=home.arpa/' /etc/systemd/resolved.conf

systemctl enable systemd-networkd.service 
systemctl enable systemd-resolved.service 

#Do this to avoid fucky DNS stuff
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

echo "-------------------------------------------------"
echo "Installing display Drivers"
echo "-------------------------------------------------"

#Should include nvidia drivers + vulkan + Cuda + OpenCL +32bit opengl
#https://wiki.hyprland.org/Nvidia/
pacman -S nvidia nvidia-utils lib32-nvidia-utils nvidia-settings libva-nvidia-driver --noconfirm --needed

echo "-------------------------------------------------"
echo "Setting up GRUB"
echo "-------------------------------------------------"

git clone https://github.com/Coopydood/HyperFluent-GRUB-Theme/ /usr/share/grub/themes/hyperfluent/

pacman -S grub efibootmgr dosfstools mtools os-prober --noconfirm --needed
#need to mount windows to see stuff
mkdir /mnt/win11
mount /dev/disk/by-id/nvme-eui.002538592140e412-part4 /mnt/win11
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id="DemonBoot"
sed -i 's/^#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/ c\GRUB_CMDLINE_LINUX_DEFAULT="quiet loglevel=3 nvidia_drm.modeset=1/"' /etc/default/grub
sed -i 's|^#GRUB_THEME.*|GRUB_THEME=/usr/share/grub/themes/hyperfluent/arch/theme.txt|' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg


echo "-------------------------------------------------"
echo "Setting up snapshots"
echo "-------------------------------------------------"

pacman -S timeshift grub-btrfs --noconfirm --needed



echo "-------------------------------------------------"
echo "Setting up audio"
echo "-------------------------------------------------"

pacman -S pipewire pipewire-audio pipewire-pulse pipewire-alsa pipewire-jack wireplumber --noconfirm --needed
systemctl --user enable pipewire pipewire-pulse wireplumber


echo "-------------------------------------------------"
echo "Installing wayland + hyprland"
echo "-------------------------------------------------"

#Following https://wiki.hyprland.org/Nvidia/
# Get base hyprland going
pacman -S egl-wayland hyprland polkit polkit-kde-agent xdg-desktop-portal-hyprland xdg-desktop-portal-gtk archlinux-xdg-menu qt5-wayland qt6-wayland --noconfirm --needed
#Chosen software for stuff
pacman -S waybar fuzzel udiskie cliphist pavucontrol kitty grim slurp gifsicle wf-recorder satty --noconfirm --needed

sed -i 's/^MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
echo "options nvidia_drm modeset=1 fbdev=1" > /etc/modprobe.d/nvidia.conf
mkinitcpio -P
#Check for errors of missing nvidia headers or whatever after mkinicpio


echo "--------------------------------------"
echo "-- Installing login manager --"
echo "--------------------------------------"

#SDDM
pacman -Suy sddm qt5-graphicaleffects qt5-quickcontrols2 qt5-svg --needed --noconfirm
git clone https://github.com/Kangie/sddm-sugar-candy /usr/share/sddm/themes/sugar-candy
mkdir /etc/sddm.conf.d/
cat <<EOF > /etc/sddm.conf.d/theme.conf
[Theme]
Current=sugar-candy
EOF

systemctl enable sddm.service


echo "--------------------------------------"
echo "-- Installing the important stuff --"
echo "--------------------------------------"

#assorted utilities
pacman -S hyfetch man btop bat neovim nano less fzf openssh yazi --noconfirm --needed

#zsh rice
pacman -S ttf-firacode-nerd starship eza zsh-syntax-highlighting zsh-autosuggestions --noconfirm --needed

#firefox
pacman -S firefox hunspell hunspell-en_us --noconfirm --needed

#U KNOW IT
pacman -S steam lib32-systemd wqy-zenhei lib32-fontconfig ttf-liberation  --noconfirm --needed

#Having the vm.max_map_count set to a low value can affect the stability and performance of some games.
#It can therefore be desirable to increase the size permanently by creating the following sysctl config file. 
echo "vm.max_map_count = 2147483642" >> /etc/sysctl.d/80-gamecompatibility.conf

#install nvchad
# doesn't work need to do it manually I think?
# git clone https://github.com/NvChad/starter ~/.config/nvim

echo "--------------------------------------"
echo "-- Installing yay/AUR/vesktop --"
echo "--------------------------------------"
#Get yay working with a hacky workaround because root can't makepkg
#this is pretty hacky lol
#all for scripting out vesktop install...
# http://allanmcrae.com/2015/01/replacing-makepkg-asroot/

pacman -S --needed --noconfirm base-devel

usermod -aG wheel nobody
sed -i 's|# %wheel ALL=(ALL:ALL) NOPASSWD: ALL|%wheel ALL=(ALL:ALL) NOPASSWD: ALL|' /etc/sudoers

mkdir /home/build
chgrp nobody /home/build
chmod g+ws /home/build
setfacl -m u::rwx,g::rwx /home/build
setfacl -d --set u::rwx,g::rwx,o::- /home/build
git clone https://aur.archlinux.org/yay-bin.git /home/build/yay-bin
chmod -R g+w /home/build/yay-bin/
cd /home/build/yay-bin/

sudo -u nobody makepkg -si --noconfirm
#yay -Y --gendb #can't get this to work in chroot, but only applies to packages that are *-git anyway
sudo -u nobody yay -Syu --devel
sudo -u nobody yay -Y --devel --save

#best linux discord client in 2024
#I'm really struggling to get this to work though
#sudo -u nobody yay -S vesktop --noconfirm --answerclean All --answerdiff None -u nobody

#Make snapshots happen on running pacman
sudo -u nobody yay -S timeshift-autosnap --noconfirm --answerclean All --answerdiff None -u nobody

# Annoying but needed for steam fonts to look nice
sudo -u nobody yay -S ttf-ms-win11-auto --noconfirm --answerclean All --answerdiff None -u nobody 

#Get alerted on read only file system error
sudo -u nobody yay -S  btrfs-desktop-notification --noconfirm --answerclean All --answerdiff None -u nobody


read -p "did this work ctrl + c to cancel early and stop the cleanup?"

sleep 5


echo "-------------------------------------------------"
echo "cleaning up"
echo "-------------------------------------------------"

#undo makepkg monstrosity
sed -i 's|%wheel ALL=(ALL:ALL) NOPASSWD: ALL|# %wheel ALL=(ALL:ALL) NOPASSWD: ALL|' /etc/sudoers
usermod -G nobody nobody        
rm -rf /home/build

#Fix permission issues caused by using chroot
#doesn't seem to work so using -v
chown -v -hR $user:$group /home/$user/


echo "-------------------------------------------------"
echo "Install Complete, You can reboot now"
echo "-------------------------------------------------"
