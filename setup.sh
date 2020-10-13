#!/bin/bash

# RUN:
# ./setup.sh

P=$PWD

fixups() {
	cd $P
	# Apply patches
	for LAYER in $(ls -1 $P/patches); do
		cd $P/workspace/layers/$LAYER
		for PATCH in $(ls -1 $P/patches/$LAYER); do
			git am $P/patches/$LAYER/$PATCH
		done
		cd $P/
	done
}

env_setup() {
	mkdir -p $P/workspace/layers
	cd $P/workspace/layers

	git clone --branch warrior git://git.yoctoproject.org/poky.git
	git clone --branch warrior git://git.openembedded.org/meta-openembedded
	git clone --branch warrior git://git.yoctoproject.org/meta-virtualization
	git clone --branch warrior git://git.yoctoproject.org/meta-cloud-services
	git clone --branch warrior git://git.yoctoproject.org/meta-security
	git clone --branch warrior git://git.yoctoproject.org/meta-intel
	git clone --branch warrior git://git.yoctoproject.org/meta-security
	git clone --branch warrior git://git.yoctoproject.org/meta-selinux
	git clone --branch warrior https://github.com/intel-iot-devkit/meta-iot-cloud.git
	git clone --branch warrior git://git.openembedded.org/meta-python2
	git clone --branch warrior https://git.yoctoproject.org/git/meta-dpdk
	git clone --branch warrior git://git.yoctoproject.org/meta-anaconda
	
	git clone --branch master https://opendev.org/starlingx/meta-starlingx.git
	cd $P
}

setup_build() {
	echo 'MACHINE ?= "intel-corei7-64"' >> conf/local.conf
	echo 'PREFERRED_PROVIDER_virtual/kernel = "linux-yocto-rt"' >> conf/local.conf
	echo 'IMAGE_FSTYPES = " tar.bz2"' >> conf/local.conf
	echo 'IMAGE_FSTYPES_remove = " wic"' >> conf/local.conf
	echo 'IMAGE_FSTYPES_remove = " ext4"' >> conf/local.conf
	echo 'EXTRA_IMAGE_FEATURES ?= "debug-tweaks"'  >> conf/local.conf
	echo 'EXTRA_IMAGE_FEATURES += "tools-sdk"' >> conf/local.conf
	echo 'EXTRA_IMAGE_FEATURES += "tools-debug"' >> conf/local.conf
	echo 'EXTRA_IMAGE_FEATURES += "package-management"' >> conf/local.conf
	echo 'DISTRO = "poky-stx"' >> conf/local.conf
	echo 'DISTRO_FEATURES_append = " anaconda-support"' >> conf/local.conf

	########### Customize local.conf:
	#echo 'SOURCE_MIRROR_URL = ""' >> conf/local.conf
	#echo 'INHERIT += "own-mirrors"' >> conf/local.conf
	echo "DL_DIR = \"$P/downloads\"" >> conf/local.conf
	echo "SSTATE_DIR = \"$P/sstate-cache\"" >> conf/local.conf
	#echo 'SSTATE_MIRRORS = ""' >> conf/local.conf
	# echo 'BB_NUMBER_THREADS = "8"' >> conf/local.conf
	# echo 'PARALLEL_MAKE = "-j 8"' >> conf/local.conf
}

setup_installer() {
	echo 'DISTRO = "anaconda"' >> conf/local.conf
	echo 'MACHINE = "intel-corei7-64"' >> conf/local.conf
	echo 'PREFERRED_PROVIDER_virtual/kernel = "linux-yocto"' >> conf/local.conf
	echo "INSTALLER_TARGET_BUILD = \"$P/workspace/build/\"" >> conf/local.conf
	echo "DL_DIR = \"$P/downloads\"" >> conf/local.conf
	echo "SSTATE_DIR = \"$P/sstate-cache\"" >> conf/local.conf
	echo 'INSTALLER_TARGET_IMAGE = "stx-image-aio"' >> conf/local.conf
	echo 'BB_NUMBER_THREADS = "8"' >> conf/local.conf
	echo 'PARALLEL_MAKE = "-j 8"' >> conf/local.conf
}

prj_setup() {
	cd $P/workspace/layers/poky
	source oe-init-build-env $P/workspace/$1

cat > conf/bblayers.conf << EOF
# POKY_BBLAYERS_CONF_VERSION is increased each time build/conf/bblayers.conf
# changes incompatibly
POKY_BBLAYERS_CONF_VERSION = "2"

BBPATH = "\${TOPDIR}"
BBFILES ?= ""

BBLAYERS ?= " \\
	$P/workspace/layers/poky/meta \\
	$P/workspace/layers/poky/meta-poky \\
	$P/workspace/layers/poky/meta-yocto-bsp \\
	$P/workspace/layers/meta-openembedded/meta-oe \\
	$P/workspace/layers/meta-openembedded/meta-filesystems \\
	$P/workspace/layers/meta-openembedded/meta-initramfs \\
	$P/workspace/layers/meta-openembedded/meta-networking \\
	$P/workspace/layers/meta-openembedded/meta-perl \\
	$P/workspace/layers/meta-openembedded/meta-python \\
	$P/workspace/layers/meta-openembedded/meta-webserver \\
	$P/workspace/layers/meta-openembedded/meta-gnome \\
	$P/workspace/layers/meta-virtualization \\
	$P/workspace/layers/meta-cloud-services \\
	$P/workspace/layers/meta-cloud-services/meta-openstack \\
	$P/workspace/layers/meta-intel \\
	$P/workspace/layers/meta-security \\
	$P/workspace/layers/meta-selinux \\
	$P/workspace/layers/meta-iot-cloud \\
	$P/workspace/layers/meta-python2 \\
	$P/workspace/layers/meta-dpdk \\
	$P/workspace/layers/meta-starlingx/meta-stx-cloud \\
	$P/workspace/layers/meta-starlingx/meta-stx-distro \\
	$P/workspace/layers/meta-starlingx/meta-stx-flock \\
	$P/workspace/layers/meta-starlingx/meta-stx-integ \\
	$P/workspace/layers/meta-starlingx/meta-stx-virt \\
	$P/workspace/layers/meta-anaconda \\
	  "
EOF
	setup_$1
	
}


prj_build() {
	cd $P/workspace/layers/poky
	source oe-init-build-env $P/workspace/$1
	bitbake $2
}

env_setup
fixups
prj_setup build 
prj_build build stx-image-aio
prj_setup installer
prj_build installer stx-image-aio-installer
echo -e "All done\nISO image: $P/workspace/installer/tmp-glibc/deploy/images/intel-corei7-64/stx-image-aio-installer-intel-corei7-64.iso"
