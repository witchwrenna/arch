Copy main.sh into your live iso and run

will download and call on the files in the following order:
installarch.sh
configarch.sh
configgit.sh
postinstall.sh

installarch.sh: get base linux kernal install pacstrap
configarch.sh: configure stuff through chroot for a basic install
cofiggit.sh: setup dotfiles support by using the default user
postinstall.sh: my personal application preferences, meant to be redeployed over and over post install

Eventually, I'll move stuff over the ansible, but I wanted to learn how to do this stuff with less abstraction

optionally, run createiso on an arch install and boot off of that, it will have main.sh included. NOT WORKING YET.