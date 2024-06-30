#!/usr/bin/env bash

#These variables get passed by main. Modify main.sh to change these variables
diskid=$1
efi=$2
root=$3
user=$4
group=$5

read -p "ensure your /etc/pacman.conf file has multilib enabled"

echo "-------------------------------------------------"
echo "Setup pacman"
echo "-------------------------------------------------"

pacman -Sy

#Need to finish setting this up
pacman -Sy base-devel reflector --needed --noconfirm #for AUR

systemctl enable fstrim.timer
systemctl enable reflector.timer

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
sed -i 's/^#Domains=.*/Domains=home.arpa/' /etc/systemd/resolved.conf

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
pacman -S egl-wayland hyprland polkit polkit-kde-agent xdg-desktop-portal-hyprland xdg-desktop-portal-gtk qt5-wayland qt6-wayland --noconfirm --needed
#Chosen software for stuff
pacman -S waybar fuzzel udiskie cliphist pavucontrol kitty grim slurp --noconfirm --needed

sed -i 's/^MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
echo "options nvidia_drm modeset=1 fbdev=1" > /etc/modprobe.d/nvidia.conf
mkinitcpio -P
Check for errors of missing nvidia headers or whatever after mkinicpio


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
pacman -S hyfetch man htop bat neovim nano less fzf openssh yazi --noconfirm --needed

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

git clone https://aur.archlinux.org/yay-bin.git ~/yay-bin
chmod -R g+w ~/yay-bin
cd ~/yay-bin

sudo makepkg -si --noconfirm
#yay -Y --gendb #can't get this to work in chroot, but only applies to packages that are *-git anyway
sudo yay -Syu --devel
sudo yay -Y --devel --save

sudo yay -S vesktop --noconfirm --answerclean All --answerdiff None --needed

#Make snapshots happen on running pacman
sudo yay -S timeshift-autosnap --noconfirm --answerclean All --answerdiff None --needed

sudo yay -S ttf-ms-win11-auto --noconfirm --answerclean All --answerdiff None --needed

sleep 5

echo "-------------------------------------------------"
echo "refresh Complete"
echo "-------------------------------------------------"