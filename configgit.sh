#!/usr/bin/env bash

echo "-------------------------------------------------"
echo "Setup git and dotfiles"
echo "-------------------------------------------------"

mkdir $HOME/.dotfiles

git config --global user.name "Witch Wrenna"
git config --global user.email witchwrenna@gmail.com
git config --global credential.credentialStore cache

alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

#Creation... it's a one time thing that i already did so including it for historical reference
creation=false

if ["$creation" = true] ; then
    git init --bare $HOME/.dotfiles
    dotfiles branch -M main
else
    git clone --bare https://github.com/witchwrenna/dotfiles $HOME/.dotfiles
    dotfiles checkout -f
fi

cd ~
dotfiles config --local status.showUntrackedFiles no
dotfiles clone https://github.com/witchwrenna/arch





# To add stuff...
# dotfiles add $Filename
# dotfiles commit -m "Updating file!"
# dotfiles push

# other commands
# dotfiles status
# dotfiles checkout