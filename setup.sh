#!/bin/bash

# RUN:
# setup.sh 

P=$PWD


fixups() {
	cd $P/workspace/layers/poky
	# if /bin/sh is symlinked to other than bash
	ls -l /bin/sh | grep -q bash || sed -i -e 's:/bin/sh:/bin/bash:g' bitbake/lib/bb/build.py
	cd $P
	# Apply patches
	for LAYER in $(ls -1 $P/patches); do
		cd $P/workspace/layers/$LAYER
		for PATCH in $(ls -1 $P/patches/$LAYER); do
			git am $P/patches/$LAYER/$PATCH
		done
		cd $P/
	done
	echo "On some build servers rabbitmq builds fail if the number of cores >> 8"
	echo "As a workaround: patching meta-stx/recipes-extended/rabbitmq to build with -j7"
	echo "and we ignore changes to meta-stx/recipes-extended/rabbitmq/rabbitmq-server_3.2.4.bbappend"
	echo "recipes-extended/rabbitmq" >> $P/workspace/meta-stx/.gitignore
	echo -n "Enter to continue: "
	read junk
}

env_setup() {
	mkdir -p $P/workspace/{layers,build}
	cd $P/workspace/layers

	git clone --branch zbsarashki/thud_stx_110919 https://github.com/zbsarashki/meta-stx.git
	git clone --branch zbsarashki/thud_stak_common https://github.com/zbsarashki/meta-starlingX.git
	git clone --branch thud git://git.yoctoproject.org/poky.git
	git clone --branch thud git://git.openembedded.org/meta-openembedded
	git clone --branch thud git://git.yoctoproject.org/meta-virtualization
        git clone --branch thud git://git.yoctoproject.org/meta-cloud-services
	git clone --branch thud git://git.yoctoproject.org/meta-selinux
	git clone --branch thud git://git.yoctoproject.org/meta-security
	git clone --branch thud https://github.com/jiazhang0/meta-secure-core.git
	git clone --branch thud https://github.com/rauc/meta-rauc.git
	git clone --branch thud git://git.yoctoproject.org/meta-intel
	git clone --branch thud git://git.yoctoproject.org/meta-intel-qat
	git clone --branch thud https://github.com/intel-iot-devkit/meta-iot-cloud.git
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
	$P/workspace/layers/meta-openembedded/meta-gnome \\
	$P/workspace/layers/meta-virtualization \\
	$P/workspace/layers/meta-cloud-services \\
	$P/workspace/layers/meta-cloud-services/meta-openstack \\
	$P/workspace/layers/meta-cloud-services/meta-openstack-aio-deploy \\
	$P/workspace/layers/meta-cloud-services/meta-openstack-compute-deploy \\
	$P/workspace/layers/meta-cloud-services/meta-openstack-controller-deploy \\
	$P/workspace/layers/meta-cloud-services/meta-openstack-qemu \\
	$P/workspace/layers/meta-cloud-services/meta-openstack-swift-deploy \\
	$P/workspace/layers/meta-secure-core/meta-signing-key \\
	$P/workspace/layers/meta-secure-core/meta-efi-secure-boot \\
	$P/workspace/layers/meta-secure-core/meta-encrypted-storage \\
	$P/workspace/layers/meta-secure-core/meta-integrity \\
	$P/workspace/layers/meta-secure-core/meta-tpm2 \\
	$P/workspace/layers/meta-secure-core/meta \\
	$P/workspace/layers/meta-security \\
	$P/workspace/layers/meta-security/meta-security-compliance \\
	$P/workspace/layers/meta-selinux \\
	$P/workspace/layers/meta-intel \\
	$P/workspace/layers/meta-intel-qat \\
	$P/workspace/layers/meta-rauc \\
	$P/workspace/layers/meta-iot-cloud \\
	$P/workspace/layers/meta-stx \\
	$P/workspace/layers/meta-starlingX \\
	"
EOF

	sed -i -e 's/^\(#MACHINE.*\"qemuarm\"\)/MACHINE \?= \"intel-corei7-64\"\n\1/g' conf/local.conf
	echo 'PREFERRED_PROVIDER_virtual/kernel = "linux-yocto"' >> conf/local.conf
	echo 'IMAGE_FSTYPES = " tar.bz2"' >> conf/local.conf
	echo 'EXTRA_IMAGE_FEATURES ?= "debug-tweaks"'  >> conf/local.conf
	echo 'EXTRA_IMAGE_FEATURES += "tools-sdk"' >> conf/local.conf
	echo 'EXTRA_IMAGE_FEATURES += "tools-debug"' >> conf/local.conf
	echo 'EXTRA_IMAGE_FEATURES += "package-management"' >> conf/local.conf

	########### Customize local.conf:
	# echo 'SOURCE_MIRROR_URL = ""' >> conf/local.conf
	# echo 'DL_DIR = ""' >> conf/local.conf
	# echo 'INHERIT += "own-mirrors"' >> conf/local.conf
	# echo 'SSTATE_MIRRORS = ""' >> conf/local.conf
	# echo 'SSTATE_DIR = ""' >> conf/local.conf

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
