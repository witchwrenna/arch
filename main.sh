#!/usr/bin/env bash

wget -P ~/ https://github.com/witchwrenna/arch/archive/master.zip
unzip ~/master.zip
mv ~/*-master ~/dir-name

bash ~/archinstall


arch-chroot /mnt sh chrootarch.sh