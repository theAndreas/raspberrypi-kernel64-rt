#!/bin/sh

dpkg -r --force-depends raspberrypi-kernel
dpkg -i ./deb-package/raspberrypi-kernel.deb

#apt-mark hold raspberrypi-kernel
