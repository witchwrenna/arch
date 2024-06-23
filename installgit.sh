#!/usr/bin/env bash
#curl -L https://shorturl.at/sB0AX > main.sh
#sh main.sh

echo "-------------------------------------------------"
echo "Setup git and dotfiles"
echo "-------------------------------------------------"

mkdir /home/lilith/dotfiles

git config --global user.name "Witch Wrenna"
git config --global user.email witchwrenna@gmail.com

git init --bare /home/lilith/dotfiles
alias dotfiles='/usr/bin/git --git-dir=/home/lilith/dotfiles/ --work-tree=/home/lilith' >> /home/lilith/.zshrc
source /home/lilith/.zshrc
dotfiles config --local status.showUntrackedFiles no

#To add stuff...
#dotfiles add $Filename
#dotfiles comment -m "Updating file!"
#dotfiles push