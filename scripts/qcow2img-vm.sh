#!/bin/bash

#echo "This script needs to run as root!"
#echo "comment the exit to use the script"
#exit 1


if [ $PWD = "/" ]; then
	echo "cannot be in /"
	exit 0;
fi

part_disk() {
	parted /dev/$qdev -s mklabel msdos
	parted -a none /dev/$qdev -s mkpart primary fat32 18kB 512MB
	parted -a none /dev/$qdev -s mkpart primary ext4 512MB 20G
	parted -a none /dev/$qdev -s mkpart primary ext4 20GB 100%
}

gen_fsystem() {
	mkdosfs /dev/${qdev}p1
	mkfs.ext4 /dev/${qdev}p2
}

mount_fs() {
	mkdir -p mnt
	mount /dev/${qdev}p2 mnt
	mkdir -p mnt/boot
	mount /dev/${qdev}p1 mnt/boot
}

umount_fs() {
	umount /dev/${qdev}p1
	umount /dev/${qdev}p2
	# rm -rf mnt
}

get_nbd_avail() {
	for x in $(find /sys/class/block/ -maxdepth 1 -regex '\/.*\/block\/nbd[0-9]+'); do
		qdev=$x
		[ ! -f $qdev/pid ] && break
	done
	echo $(basename $qdev)
}

install_fs() {
	tar -C mnt -xjpf $rfsimg

	cat > $PWD/mnt/boot/loader/entries/boot.conf << \EOF
title boot
linux /bzImage
options LABEL=boot rootwait console=ttyS0,115200 root=/dev/sda2 selinux=0
EOF
	# mv mnt/boot/bzImage-.*-yocto-standard mnt/boot/bzImage
	mv mnt/boot/bzImage-5.0.19-yocto-standard mnt/boot/bzImage

}

gen_qcow2() {
	
	# Load nbd module
	modprobe nbd max_part=16
	# create disk
	qemu-img create -f qcow2 $dimg $dsz

	# connect the nbd device

	qdev=$(get_nbd_avail)
	echo using $qdev

	qemu-nbd -c /dev/$qdev $dimg

	part_disk 
	gen_fsystem 
	mount_fs 

	install_fs 

cat << \EOF
Dropping into Shell now. This will give you a chance to modify and inspect the filesystem.
exit once done.
EOF
	/bin/bash

cat << \EOF
Back from shell. Umounting fs. May take a while.
EOF

	umount_fs 
	qemu-nbd -d /dev/$qdev 
}

gen_raw() {
	echo "not implemented yet"
	exit 0
}

stashed_this_for_now() {
mkdosfs /dev/mapper/$(basename $ldev)p1
mkfs.ext4 /dev/mapper/$(basename $ldev)p2
mkdir -p mnt
mount /dev/mapper/$(basename $ldev)p2 mnt
mkdir mnt/boot
mount /dev/mapper/$(basename $ldev)p1 mnt/boot

tar -C mnt -xvjpf $rfsimg

cat > $PWD/mnt/boot/loader/entries/boot.conf << \EOF
title boot
linux /bzImage
options LABEL=boot rootwait console=ttyS0,115200 root=/dev/hda2 selinux=0
EOF

mv $PWD/mnt/boot/bzImage-4.18.33-yocto-standard $PWD/mnt/boot/bzImage

umount mnt/boot
umount mnt
kpartx -d $ldev
losetup -d $ldev
}

usage() {
	echo "$0 -f <qcow2|raw> -i <abs/path/to/tar.bz2> -d <disk_image_name> -s <size in GB>"
	echo "i.e.: $0 -f qcow2 -i $PWD/stx-image-aio.tar.bz2 -d disk-image.qcow2 -s 220"
	echo "i.e.: $0 -f qcow2 -n : list available nbd"
	exit 0
}


TEMP=$(getopt -o nf:i:d:s: -n "$0" -- "$@")
eval set -- "$TEMP"
unset TEMP
while true; do
	case $1 in
		'-n')
			get_nbd_avail
			exit 0
			;;
		'-f')
			imgfmt=$2
			shift 2
			;;
		'-i')
			rfsimg=$2
			shift 2
			;;
		'-d')
			dimg=$2
			shift 2
			;;
		'-s')
			dsz="$2"G
			shift 2
			;;
		'--')
			shift
			break
			;;
		*)
			usage
			;;
	esac
done

[ -z $imgfmt ] && usage
[ -z $rfsimg ] && usage
[ -z $dimg ] && usage
[ -z $dsz ] && usage

echo -e -n "Generating image: $dimg of size $dsz with contents from $rfsimg in $PWD!\nIs this correct (y/n)?"
read ans

if [ $ans != 'y' ]; then 
	echo "OK: exiting"
	exit 0
fi

gen_$imgfmt

echo -e -n "image: $dimg of size $dsz with contents from $rfsimgis: $PWD!\n"
