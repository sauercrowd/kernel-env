#!/bin/bash
INITRD="boot/initramfs-vanilla"
KERNEL='linux-4.20.1/arch/x86/boot/bzImage'
FS_FILE="alpine.img"


APPEND="root=/dev/sda1 modules=sd-mod,usb-storage,ext4 nomodesetrootfstype=ext4 console=ttyS0,9600"

set -e
set -x

qemu-system-x86_64 -kernel $KERNEL \
        -enable-kvm -m 256 \
        -initrd $INITRD \
        -drive file=$FS_FILE,format=raw,index=0,media=disk \
        -nographic -append "$APPEND"
