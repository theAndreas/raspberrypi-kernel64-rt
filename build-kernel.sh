#!/bin/bash

# Set branch or tag of rpi linux kernel (https://github.com/raspberrypi/linux)
# For branches see: https://github.com/raspberrypi/linux/branches (example rpi-6.1.y)
# For tag sees: https://github.com/raspberrypi/linux/tags (example 1.20230405)
RPI_LINUX_KERNEL_BRANCH=1.20230405
RT_KERNEL_PATCH_REPO_URL=https://mirrors.edge.kernel.org/pub/linux/kernel/projects/rt
RPI_KERNEL_REPO_URL=https://github.com/raspberrypi/linux

# Do not change!
RPI_KERNEL_REPO_TREE_URL=${RPI_KERNEL_REPO_URL}/tree
RPI_KERNEL_BRANCH_URL=${RPI_KERNEL_REPO_TREE_URL}/${RPI_LINUX_KERNEL_BRANCH}

# Do not change! Values are used by build-deb-package.sh
INSTALL_FOLDER_PATH=./install
BUILD_FOLDER_PATH=./build

echo "Clear folders ${INSTALL_FOLDER_PATH}, ${BUILD_FOLDER_PATH}, ./linux"
#rm -rf ${INSTALL_FOLDER_PATH}
#mkdir -p ${INSTALL_FOLDER_PATH}
#rm -rf ${BUILD_FOLDER_PATH}
#mkdir -p ${BUILD_FOLDER_PATH}
#rm -rf ${linux}

echo "Cloning kernel branch ${RPI_LINUX_KERNEL_BRANCH} (${RPI_KERNEL_BRANCH_URL})"
#git ${RT_KERNEL_PATCH_REPO_URL} --branch ${RPI_LINUX_KERNEL_BRANCH} --depth=1

KERNEL_MAKEFILE="linux/Makefile"
KERNEL_VERSION=$(grep -m 1 VERSION ${KERNEL_MAKEFILE} | sed 's/^.*= //g')
KERNEL_PATCHLEVEL=$(grep -m 1 PATCHLEVEL ${KERNEL_MAKEFILE} | sed 's/^.*= //g')
KERNEL_SUBLEVEL=$(grep -m 1 SUBLEVEL ${KERNEL_MAKEFILE} | sed 's/^.*= //g')

KERNEL_VERSION_PATCHLEVEL_SUBLEVEL=${KERNEL_VERSION}.${KERNEL_PATCHLEVEL}.${KERNEL_SUBLEVEL}
LINUX_KERNEL_VERSION_PATCHLEVEL=${KERNEL_VERSION}.${KERNEL_PATCHLEVEL}

echo "Branch contains kernel version ${KERNEL_VERSION_PATCHLEVEL_SUBLEVEL}"

LINUX_KERNEL_VERSION_PATCHLEVEL=${KERNEL_VERSION}.${KERNEL_PATCHLEVEL}

RT_KERNEL_RT_KERNEL_PATCH_FILENAME_WITHOUT_EXTENSION=$(curl -s ${RT_KERNEL_PATCH_REPO_URL}/${LINUX_KERNEL_VERSION_PATCHLEVEL}/ | sed -n 's:.*<a href="\(.*\).patch.gz">.*:\1:p' | sort -V | tail -1)
RT_KERNEL_PATCH_FILENAME=${RT_KERNEL_RT_KERNEL_PATCH_FILENAME_WITHOUT_EXTENSION}.patch.gz
RT_KERNEL_PATCH_VERSION=$(echo "${RT_KERNEL_RT_KERNEL_PATCH_FILENAME_WITHOUT_EXTENSION}" | sed "s/patch-//")
RT_KERNEL_PATCH_URL=${RT_KERNEL_PATCH_REPO_URL}/${LINUX_KERNEL_VERSION_PATCHLEVEL}/${RT_KERNEL_PATCH_FILENAME}

echo "Retrieved latest realtime patch for kernel ${LINUX_KERNEL_VERSION_PATCHLEVEL}: ${RT_KERNEL_PATCH_FILENAME}"

echo "Creating ${INSTALL_FOLDER_PATH}/README.txt"
cat << EOF > README.txt
Kernel version: ${KERNEL_VERSION_PATCHLEVEL_SUBLEVEL} (${RPI_KERNEL_BRANCH_URL})
Realtime patch version: ${RT_KERNEL_PATCH_VERSION} (${RT_KERNEL_PATCH_URL})
EOF

exit

cd linux

echo "Executing mrproper"
make ARCH=arm64 mrproper

echo "Downloading realtime kernel patch"
wget ${RT_KERNEL_PATCH_URL}
gunzip ${RT_KERNEL_PATCH_FILENAME}

echo "Apply realtime kernel patch"
cat ${RT_KERNEL_RT_KERNEL_PATCH_FILENAME_WITHOUT_EXTENSION}.patch | patch -p1

echo "Creating kernel configuration"
KERNEL=kernel8
make O=../${BUILD_FOLDER_PATH} ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- bcm2711_defconfig

echo "Configuring kernel"
./scripts/config --file ../${BUILD_FOLDER_PATH}/.config --disable CONFIG_VIRTUALIZATION
./scripts/config --file ../${BUILD_FOLDER_PATH}/.config --enable CONFIG_PREEMPT_RT
./scripts/config --file ../${BUILD_FOLDER_PATH}/.config --disable CONFIG_RCU_EXPERT
./scripts/config --file ../${BUILD_FOLDER_PATH}/.config --enable CONFIG_RCU_BOOST
./scripts/config --file ../${BUILD_FOLDER_PATH}/.config --enable CONFIG_SMP
./scripts/config --file ../${BUILD_FOLDER_PATH}/.config --disable CONFIG_BROKEN_ON_SMP
./scripts/config --file ../${BUILD_FOLDER_PATH}/.config --set-val CONFIG_RCU_BOOST_DELAY 500

echo "Building kernel to ${BUILD_FOLDER_PATH}"
make -j8 O=../${BUILD_FOLDER_PATH}/ ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- Image modules dtbs

echo "Installing kernel image, MOD, DTB and HDR to ${INSTALL_FOLDER_PATH} with default structure and naming"
export INSTALL_PATH=../${INSTALL_FOLDER_PATH}
export INSTALL_MOD_PATH=../${INSTALL_FOLDER_PATH}
export INSTALL_HDR_PATH=../${INSTALL_FOLDER_PATH}/usr
export INSTALL_DTBS_PATH=../${INSTALL_FOLDER_PATH}/boot/dtbs
make O=../${BUILD_FOLDER_PATH} ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- modules_install dtbs_install headers_install
cp ../${BUILD_FOLDER_PATH}/arch/arm64/boot/Image ../${INSTALL_FOLDER_PATH}/boot

echo "Installing device tree overlay README to ${INSTALL_FOLDER_PATH}/boot/dtbs"
cp ./arch/arm64/boot/dts/overlays/README ${INSTALL_DTBS_PATH}/overlays

cd ../${INSTALL_FOLDER_PATH}

echo "Creating ${INSTALL_FOLDER_PATH}/README.txt"
cat << EOF > README.txt
Kernel version: ${KERNEL_VERSION_PATCHLEVEL_SUBLEVEL} (${RPI_KERNEL_BRANCH_URL})
Realtime patch version: ${RT_KERNEL_PATCH_VERSION} (${RT_KERNEL_PATCH_URL})
EOF
