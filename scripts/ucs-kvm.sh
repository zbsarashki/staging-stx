#!/bin/bash

# Edit this file as needed

BIOS="$(dirname $0)/bios-secure.bin"
disk0=/path/to/disk-img.qcow2
disk1=/path/to/scratch_img.raw

SCSI_CONTROLLER="-device virtio-scsi-pci,id=scsi0" 
DISK0=" \
	-drive file=$disk0,if=none,format=qcow2,discard=unmap,aio=native,cache=none,id=disk0-id \
	-device scsi-hd,drive=disk0-id,bus=scsi0.0,channel=0,scsi-id=0,lun=0 \
	"

DISK1=" \
	-drive file=$disk1,if=none,format=raw,discard=unmap,aio=native,cache=none,id=disk1-id \
	-device scsi-hd,drive=disk1-id,bus=scsi0.0,scsi-id=1,lun=0 \
	"

PFLASH0="-drive if=pflash,unit=0,format=raw,file=$BIOS,readonly=on"

#[std|cirrus|vmware|qxl|xenfb|tcx|cg3|virtio|none]
VGA="-vga cg3"
DEVS="-device piix3-usb-uhci "
#NET0="-net nic,macaddr=00:53:00:12:a4:6d" 
#NET1="-net nic,macaddr=00:54:00:12:a4:6d"

NET0="-device e1000,netdev=net0,mac=00:53:00:12:a4:6d" 
NET1="-device e1000,netdev=net1,mac=00:54:00:12:a4:6d" 

NET0_SCRIPT="-netdev tap,id=net0,script=/etc/ovs-ifup,downscript=/etc/ovs-ifdown"
NET1_SCRIPT="-netdev tap,id=net1,script=/etc/qemu-ifup,downscript=/etc/qemu-ifdown"
NET_SCRIPT="$NET0_SCRIPT $NET1_SCRIPT"

DAEMONIZE="-vnc :15 -vnc :16 -daemonize"
# TPM=" -chardev socket,id=chrtpm,path=/tmp/mytpm2/swtpm-sock -tpmdev emulator,id=tpm0,chardev=chrtpm -device tpm-tis,tpmdev=tpm0"
EXTRA_OPTS="-net none $TPM $CDROM $1"
MONITOR=" -monitor telnet::2345,server,nowait"


# DISK=" "
#DAEMONIZE=""
MONITOR=""

echo $NET_SCRIPT
taskset -c 3,4 \
qemu-system-x86_64 --enable-kvm  -cpu host -m 4096M -smp 2 \
	$FLASHOPT \
	$PFLASH0 \
	$PFLASH1 \
	$SCSI_CONTROLLER \
	$DISK0 \
	$DISK1 \
	$DEVS \
	$NET0 \
	$NET1 \
	$NET_SCRIPT \
        -serial telnet::2234,server,wait \
	$MONITOR \
	$DAEMONIZE \
	$EXTRA_OPTS
