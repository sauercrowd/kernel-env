#!/bin/bash
ALPINE_ARCH=x86_64
ALPINE_MAIN_VERSION=v3.8
ALPINE_VERSION=3.8.2

SIZE_GB=5
FS_FILE=./alpine.img
MOUNT_DIR=./alpine-mount
PARTITION_START=2048
SECTOR_SIZE=512

SETUP_DIR=`pwd`

create_fs_file(){
	cd $SETUP_DIR
	dd if=/dev/zero of=$FS_FILE bs=1M count=$((1024*$SIZE_GB)) status=progress
}

create_dos_table(){
	cd $SETUP_DIR
	fdisk $FS_FILE <<EOF
o
w
EOF
}

create_root_partition(){
	cd $SETUP_DIR
	fdisk $FS_FILE <<EOF
n
p
1
$PARTITION_START

w
EOF
}

format_root_partition(){
	cd $SETUP_DIR
	echo "y" | mkfs.ext4 -q -E offset=$(($PARTITION_START * $SECTOR_SIZE)) $FS_FILE
}

mount_root_partition(){
	echo "Cleaning $MOUNT_DIR"
	rm -rf $SETUP_DIR/$MOUNT_DIR
	mkdir -p $SETUP_DIR/$MOUNT_DIR
	cd $SETUP_DIR
	sudo mount -t ext4 -o offset=$(($PARTITION_START * $SECTOR_SIZE)) $FS_FILE $MOUNT_DIR
}

bootstrap_root_partition(){
	cd $SETUP_DIR
	cd $MOUNT_DIR
	sudo wget http://dl-cdn.alpinelinux.org/alpine/$ALPINE_MAIN_VERSION/releases/$ALPINE_ARCH/alpine-minirootfs-$ALPINE_VERSION-$ALPINE_ARCH.tar.gz
	sudo tar xvf alpine-minirootfs-$ALPINE_VERSION-$ALPINE_ARCH.tar.gz
	sudo rm alpine-minirootfs-$ALPINE_VERSION-$ALPINE_ARCH.tar.gz
	cd ..
}

enable_serial_console(){
	sudo bash -c "echo ttyS0 >> $SETUP_DIR/$MOUNT_DIR/etc/securetty"
	sudo bash -c "echo 'ttyS0::respawn:/sbin/getty -L ttyS0 115200 vt100' >> $SETUP_DIR/$MOUNT_DIR/etc/inittab"
}

unmount_root_partition(){
	sudo umount $SETUP_DIR/$MOUNT_DIR
	rm -r $SETUP_DIR/$MOUNT_DIR
}

get_kernel_and_initrd(){
	cd $SETUP_DIR
	rm -rf boot
	wget "http://dl-cdn.alpinelinux.org/alpine/$ALPINE_MAIN_VERSION/releases/$ALPINE_ARCH/alpine-netboot-$ALPINE_VERSION-$ALPINE_ARCH.tar.gz"
	tar xvf alpine-netboot-$ALPINE_VERSION-$ALPINE_ARCH.tar.gz
	rm alpine-netboot-$ALPINE_VERSION-$ALPINE_ARCH.tar.gz
}

main(){
	set -e
	echo "Removing $FS_FILE"
	rm -f $FS_FILE

	echo "Creating FS File"
	create_fs_file
	echo "Creating DOS Table"
	create_dos_table
	echo "Creating root partition"
	create_root_partition
	echo "Formatting root partition"
	format_root_partition
	echo "Mounting root partition"
	mount_root_partition
	echo "Bootstrap root partition"
	bootstrap_root_partition
	echo "Enabling serial console"
	enable_serial_console
	echo "Unmounting root partition"
	unmount_root_partition
	echo "Downloading kernel and initramfs"
	get_kernel_and_initrd
}

main
