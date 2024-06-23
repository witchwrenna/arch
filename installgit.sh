#!/usr/bin/env bash

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