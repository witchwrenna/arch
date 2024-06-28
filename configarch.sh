#!/usr/bin/env bash

#These variables get passed by main. Modify main.sh to change these variables
diskid=$1
efi=$2
root=$3
user=$4
group=$5

systemctl enable fstrim.timer


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

#Let's enable parallel downloads, colours, and sync the latest stuff :3
sed -i 's/#ParallelDownloads.*/ParallelDownloads=10/' /etc/pacman.conf
sed -i '/Color/s/^#//g' /etc/pacman.conf

#lol
#echo "ILoveCandy" >> /etc/pacman.conf

pacman -S base-devel reflector --needed --noconfirm #for AUR

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
ln -sf ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf


echo "-------------------------------------------------"
echo "Installing display Drivers"
echo "-------------------------------------------------"

#Should include nvidia drivers + vulkan + Cuda + OpenCL
#https://wiki.hyprland.org/Nvidia/
pacman -S nvidia nvidia-utils nvidia-settings libva-nvidia-driver --noconfirm --needed


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

pacman -S refind efibootmgr --noconfirm --needed

mkdir -p /boot/efi/EFI/refind
cp /usr/share/refind/refind_x64.efi /boot/efi/EFI/refind/
mkdir -p /boot/efi/EFI/refind/drivers_x64
cp /usr/share/refind/drivers_x64/btrfs_x64.efi /boot/efi/EFI/refind/drivers_x64/

efibootmgr --create --disk $diskid --part 1 --loader /EFI/refind/refind_x64.efi --label "DemonBoot" --unicode
cp -r /usr/share/refind/icons /boot/efi/EFI/refind/


#create $UUID from fstab because UUID changes after mkfs
read UUID <<< $(cat /etc/fstab | grep -A1 Root | grep UUID | awk -v col=1 '{print $col}' | cut -d "=" -f 2)
PARTUUID=$(blkid -t UUID=$UUID -s PARTUUID -o value)
echo "$PARTUUID"

cat <<BOOT > /boot/refind_linux.conf
"Boot using default options"     "root=PARTUUID=$PARTUUID rootflags=subvol=@ rw loglevel=3 quiet nvidia_drm.modeset=1"
"Boot using fallback initramfs"  "root=PARTUUID=$PARTUUID rootflags=subvol=@ rw initrd=boot\initramfs-%v-fallback.img"
"Boot to terminal"               "root=PARTUUID=$PARTUUID rootflags=subvol=@ rw systemd.unit=multi-user.target"
BOOT

#Get theme installed
#modify refind.conf in config folder if changing theme
git clone https://github.com/evanpurkhiser/rEFInd-minimal /boot/efi/EFI/refind/themes/rEFInd-minimal/
cp /boot/efi/EFI/refind/themes/rEFInd-minimal/icons/os-arch.png /boot/vmlinuz-linux.png

cp /usr/share/refind/refind.conf-sample /boot/efi/EFI/refind/refind.conf
sed -i '/extra_kernel_version_strings/s/^#//g' /boot/efi/EFI/refind/refind.conf
sed -i '/enable_mouse/s/^#//g' /boot/efi/EFI/refind/refind.conf


#echo "include themes/rEFInd-minimal/theme.conf" >> /boot/efi/EFI/refind/refind.conf


echo "-------------------------------------------------"
echo "Setting up snapshots"
echo "-------------------------------------------------"

pacman -S timeshift --noconfirm --needed



echo "-------------------------------------------------"
echo "Setting up audio"
echo "-------------------------------------------------"

pacman -S pipewire pipewire-audio pipewire-pulse pipewire-alsa pipewire-jack wireplumber --noconfirm --needed
systemctl --user enable pipewire pipewire-pulse wireplumber


echo "-------------------------------------------------"
echo "Installing wayland + hyprland"
echo "-------------------------------------------------"

#Following https://wiki.hyprland.org/Nvidia/
pacman -S egl-wayland hyprland waybar wofi kitty polkit polkit-kde-agent xdg-desktop-portal-hyprland xdg-desktop-portal-gtk qt5-wayland qt6-wayland --noconfirm --needed

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
pacman -S hyfetch man htop bat neovim nano less fzf openssh --noconfirm --needed

#zsh rice
pacman -S ttf-firacode-nerd starship eza zsh-syntax-highlighting zsh-autosuggestions --noconfirm -needed

#firefox
pacman -S firefox --noconfirm --needed

#install nvchad
# doesn't work need to do it manually I think?
# git clone https://github.com/NvChad/starter ~/.config/nvim

echo "--------------------------------------"
echo "-- Installing yay/AUR/vesktop --"
echo "--------------------------------------"
#Get yay working with a hacky workaround because root can't makepkg
#this is pretty hacky lol
#all for scripting out vesktop install...

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
yay -Syu --devel
yay -Y --devel --save

#best discord client in 2024
sudo sh -c "yes | yay -S vesktop --noconfirm --answerclean All --answerdiff All" -u nobody

#Make snapshots happen on running pacman
sudo sh -c "yes | yay -S timeshift-autosnap --noconfirm --answerclean All --answerdiff All" -u nobody

#undo this monstrosity
sed -i 's|%wheel ALL=(ALL:ALL) ALL NOPASSWD|# %wheel ALL=(ALL:ALL) NOPASSWD: ALL|' /etc/sudoers
usermod -G nobody nobody        
rm -rf /home/build


echo "-------------------------------------------------"
echo "cleaning up"
echo "-------------------------------------------------"

#Fix permission issues caused by using chroot
#doesn't seem to work so using -v
chown -v -hR $user:$group /home/$user/

ls -la /home/lilith/


echo "-------------------------------------------------"
echo "Install Complete, You can reboot now"
echo "-------------------------------------------------"