#!/bin/bash

dpkg -r --force-depends raspberrypi-kernel
dpkg -i ./deb-package/raspberrypi-kernel_1.20230405-1_arm64.deb

#apt-mark hold raspberrypi-kernel
