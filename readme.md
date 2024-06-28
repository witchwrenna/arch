Copy main.sh into your live iso and run

will download and call on the files in the following order:
installarch.sh
configarch.sh
postinstall.sh

installarch.sh: get base linux kernal install pacstrap
configarch.sh: configure stuff through chroot for a basic install
postinstall.sh: my personal application preferences, meant to be redeployed over and over post install. Relies on hyprland for initial install. If hyprland is not install, need to use another method.

This process depends upon assumptions that you will use the dotfiles available at www.github.com/witchwrenna/dotfiles in order to fully configure everything. Otherwise, some installed stuff will not be hooked up and connected properly

Eventually, I'll move stuff over the ansible, but I wanted to learn how to do this stuff with less abstraction

optionally, run createiso on an arch install and boot off of that, it will have main.sh included. NOT WORKING YET.