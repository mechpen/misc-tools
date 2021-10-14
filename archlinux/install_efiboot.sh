#!/bin/bash

part=$(lsblk -O -J | jq -r '.blockdevices[].children[] | select(.fstype == "crypto_LUKS") | {name: .name, uuid: .uuid}')
part_name=$(echo $part | jq -r .name)
part_uuid=$(echo $part | jq -r .uuid)
disk_name=$(lsblk -O -J | jq -r ".blockdevices[] | select(.children[].uuid == \"$part_uuid\") | .name")

echo ">>> disk $disk_name partition $part_name"
sudo efibootmgr -c -d /dev/$disk_name -L linux -l vmlinuz --unicode "cryptdevice=UUID=$part_uuid:root root=/dev/mapper/root rw initrd=\initrd"
sudo efibootmgr -c -d /dev/$disk_name -L linux.old -l vmlinuz.old --unicode "cryptdevice=UUID=$part_uuid:root root=/dev/mapper/root rw initrd=\initrd.old"
