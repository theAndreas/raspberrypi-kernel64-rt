#!/bin/sh

dpkg -r --force-depends raspberrypi-kernel
dpkg -i ./deb-package/raspberrypi-kernel_1.20230317-1_arm64.deb

#apt-mark hold raspberrypi-kernel
