#!/usr/bin/env bash

curl -LO https://github.com/witchwrenna/arch/archive/master.zip
gunzip ~/master.zip
mv ~/*-master ~/dir-name

bash ~/archinstall


arch-chroot /mnt sh chrootarch.sh