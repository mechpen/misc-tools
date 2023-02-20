#!/bin/bash

# should run this within kernel src dir

sudo make modules_install
sudo make headers_install
sudo cp arch/x86_64/boot/bzImage /boot/vmlinuz

sudo mkinitcpio -p vmlinuz
sudo mv /boot/initrd.img /boot/initrd
