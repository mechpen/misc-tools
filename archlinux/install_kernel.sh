#!/bin/bash

# should run this within kernel src dir

sudo make modules_install
sudo make headers_install
sudo cp --backup --suffix=.old arch/x86_64/boot/bzImage /boot/vmlinuz

sudo mkinitcpio -p vmlinuz
sudo mv --backup --suffix=.old /boot/initrd.img /boot/initrd
