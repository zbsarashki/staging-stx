#!/bin/bash

# RUN:
# setup.sh 

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
	mkdir -p $P/workspace/{layers,build}
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
	git clone --branch master https://github.com/zbsarashki/meta-stx.git
	git clone --branch master https://github.com/zbsarashki/meta-starlingX.git
	cd $P
}

prj_setup() {
	cd $P/workspace/layers/poky
	source oe-init-build-env $P/workspace/build

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
	$P/workspace/layers/meta-openembedded/meta-networking \\
	$P/workspace/layers/meta-openembedded/meta-filesystems \\
	$P/workspace/layers/meta-openembedded/meta-perl \\
	$P/workspace/layers/meta-openembedded/meta-python \\
	$P/workspace/layers/meta-openembedded/meta-webserver \\
	$P/workspace/layers/meta-openembedded/meta-initramfs \\
	$P/workspace/layers/meta-virtualization \\
	$P/workspace/layers/meta-cloud-services \\
	$P/workspace/layers/meta-cloud-services/meta-openstack \\
	$P/workspace/layers/meta-intel \\
	$P/workspace/layers/meta-security \\
	$P/workspace/layers/meta-security/meta-security-compliance \\
	$P/workspace/layers/meta-selinux \\
	$P/workspace/layers/meta-iot-cloud \\
	$P/workspace/layers/meta-python2 \\
	$P/workspace/layers/meta-dpdk \\
	$P/workspace/layers/meta-stx \\
	$P/workspace/layers/meta-starlingX \\
	"
EOF

	sed -i -e 's/^\(#MACHINE.*\"qemuarm\"\)/MACHINE \?= \"intel-corei7-64\"\n\1/g' conf/local.conf
	echo 'PREFERRED_PROVIDER_virtual/kernel = "linux-yocto"' >> conf/local.conf
	echo 'IMAGE_FSTYPES = " tar.bz2 live"' >> conf/local.conf
	echo 'LABELS_LIVE = "install"' >> conf/local.conf
	echo 'EXTRA_IMAGE_FEATURES ?= "debug-tweaks"'  >> conf/local.conf
	echo 'EXTRA_IMAGE_FEATURES += "tools-sdk"' >> conf/local.conf
	echo 'EXTRA_IMAGE_FEATURES += "tools-debug"' >> conf/local.conf
	echo 'EXTRA_IMAGE_FEATURES += "package-management"' >> conf/local.conf
	echo 'DISTRO = "poky-stx"' >> conf/local.conf

	########### Customize local.conf:
	#echo 'SOURCE_MIRROR_URL = ""' >> conf/local.conf
	#echo 'INHERIT += "own-mirrors"' >> conf/local.conf
	#echo 'DL_DIR = "/path to download"' >> conf/local.conf
	#echo 'SSTATE_DIR = "/path to sstate-cache"' >> conf/local.conf
	#echo 'SSTATE_MIRRORS = ""' >> conf/local.conf

}


prj_build() {
	cd $P/workspace/layers/poky
	source oe-init-build-env $P/workspace/build
	bitbake stx-image-aio
}

env_setup
fixups
prj_setup
prj_build
