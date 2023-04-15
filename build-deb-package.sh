#!/bin/bash

DEB_PACKAGE_VERSION_WITHOUT_EPOCHE=1.20230317-1
DEB_PACKAGE_VERSION=1:${DEB_PACKAGE_VERSION_WITHOUT_EPOCHE}
DEB_PACKAGE_FOLDER_PATH=./deb-package

# Do not change!
PACKAGE_NAME=raspberrypi-kernel
PACKAGE_FILE_NAME=${PACKAGE_NAME}_${DEB_PACKAGE_VERSION_WITHOUT_EPOCHE}_arm64.deb
PACKAGE_NAME_FOLDER_PATH=${DEB_PACKAGE_FOLDER_PATH}/${PACKAGE_NAME}
KERNEL_IMAGE_FILE_NAME=kernel8.img
# Do not change! Must be the same value as ${INSTALL_FOLDER} in build-kernel.sh
INSTALL_FOLDER_PATH=./install

rm -rf ${DEB_PACKAGE_FOLDER_PATH}
mkdir -p ${PACKAGE_NAME_FOLDER_PATH}

INSTALL_MOD_PATH=${PACKAGE_NAME_FOLDER_PATH}
INSTALL_DTBS_PATH=${INSTALL_MOD_PATH}/boot

mkdir -p ${INSTALL_MOD_PATH}
mkdir -p ${INSTALL_MOD_PATH}/boot
mkdir -p ${INSTALL_DTBS_PATH}/overlays/

echo "Copying kernel modules"
cp -r ${INSTALL_FOLDER_PATH}/lib ${PACKAGE_NAME_FOLDER_PATH}/lib

echo "Copying kernel device tree blobs"
cp ${INSTALL_FOLDER_PATH}/boot/dtbs/broadcom/* ${INSTALL_DTBS_PATH}

echo "Copying and renaming the kernel image"
cp ${INSTALL_FOLDER_PATH}/boot/Image ${INSTALL_DTBS_PATH}/${KERNEL_IMAGE_FILE_NAME}

echo "Copying kernel device tree blobs overlays"
cp ${INSTALL_FOLDER_PATH}/boot/dtbs/overlays/* ${INSTALL_DTBS_PATH}/overlays

echo "Copying README.txt"
cp ${INSTALL_FOLDER_PATH}/README.txt ${DEB_PACKAGE_FOLDER_PATH}

cd ${PACKAGE_NAME_FOLDER_PATH}

mkdir -p DEBIAN
cd DEBIAN

echo "Creating control file"
cat << EOF > control
Package: ${PACKAGE_NAME}
Source: raspberrypi-firmware
Installed-Size: `du -ks ../|cut -f 1`
Version: ${DEB_PACKAGE_VERSION}
Architecture: arm64
Maintainer: Andreas Burnickl <a.burnickl@gmail.com>
Breaks: raspberrypi-bootloader (<< 1.20160324-1)
Replaces: raspberrypi-bootloader (<< 1.20160324-1)
Provides: linux-image, wireguard-modules (= 1.0.0)
Section: kernel
Priority: optional
Multi-Arch: foreign
Homepage: https://github.com/raspberrypi/firmware
Description: Raspberry Pi bootloader.
 This package contains the Raspberry Pi Realtime Linux kernel (PREEMPT_RT).
EOF


echo "Creating post install file"
cat << EOF > postinst
#!/bin/bash
chmod -R +x /boot/overlays
chmod +x /boot/*.img
chmod +x /boot/*.dtb
EOF
chmod 0755 postinst

cd ../..

echo "Building debian package"
dpkg-deb --build --root-owner-group -Zxz ${PACKAGE_NAME}
mv ${PACKAGE_NAME}.deb ${PACKAGE_FILE_NAME}

echo "Created package: $(realpath ${PACKAGE_FILE_NAME})"
