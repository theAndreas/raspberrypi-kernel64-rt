# raspberrypi-kernel64-rt

Realtime kernel package for 64-bit raspberry pi (kernel version `6.1.21` and package `raspberrypi-kernel_1.20230405-1_arm64.deb` in version (with epoche) `1:1.20230405-1`).

To use LinuxCNC on an raspberry pi a realtime kernel is needed. Unfortunately there is no official package in the repository. So I decided to do it on my own as described [here](https://forum.linuxcnc.org/9-installing-linuxcnc/47662-installing-linuxcnc-2-9-on-raspberry-pi-4-with-preempt-rt-kernel).

The official [raspberry pi kernel](https://github.com/raspberrypi/linux.git) with the [realtime patch](https://mirrors.edge.kernel.org/pub/linux/kernel/projects/rt/) is taken.

The kernel is cross compiled (Kubuntu 22.10) as described [here](https://www.raspberrypi.com/documentation/computers/linux_kernel.html). Creating an raspberrypi-kernel package (like the official one) is very complex (see [here](https://raspberrypi.stackexchange.com/a/94827)), therefore I am using a quick and dirty solution which is described later. This package replaces the `raspberrypi-kernel_<version>_arm64.deb` from the offical [repository](https://archive.raspberrypi.org/debian/pool/main/r/raspberrypi-firmware).

The kernel is configured as follows (was adopted from [rpi-rt-kernel](https://github.com/remusmp/rpi-rt-kernel)):

```console
--disable CONFIG_VIRTUALIZATION
--enable CONFIG_PREEMPT_RT
--disable CONFIG_RCU_EXPERT
--enable CONFIG_RCU_BOOST
--enable CONFIG_SMP
--disable CONFIG_BROKEN_ON_SMP
--set-val CONFIG_RCU_BOOST_DELAY 500
```
# Building the realtime kernel locally (cross compile)

First install Git and the build dependencies:

```console
sudo apt install git bc bison flex libssl-dev make libc6-dev libncurses5-dev
```

Install the 64-bit toolchain for a 64-bit kernel:

```console
sudo apt install crossbuild-essential-arm64
```

Checkout the branch which fits to your installed official `raspberrypi-kernel_<version>_arm64.deb` version:

```console
# Master always provides the latest supported version.
git clone https://github.com/theAndreas/raspberrypi-kernel64-rt -b <version> --depth 1
```

Run the kernel build script:

```console
cd raspberrypi-kernel64-rt
sh build-kernel.sh
```

The kernel is built into the `./build` folder. All necessary files are installed into the `./install` folder with default structure. This structure is different to the raspberry pi structure. The files can not be copied to the raspberry pi sd card! If you want to install the kernel without the package, the structure in the `./deb-package/raspberrypi-kernel` folder must be used.

# Building the realtime kernel package

Run the debian package build script:

```console
sh build-deb-package.sh
```

The `raspberrypi-kernel_<version>_arm64.deb` is located in the ./deb-package folder.

# Installing the realtime kernel package

First backup your sd card image! The old kernel is not backed up!

As already described, building a debian kernel package is not that easy, because of the vfat boot partition. So the built package can only be installed, but not reinstalled or upgraded. Therefore the old package must be removed with ignoring the dependencies. Only then the new package can be installed. This can not be done with `apt`. Only `dpkg` allows this.

Copy the `raspberrypi-kernel_<version>_arm64.deb` to your raspberry pi and call the following commands:

```console
sudo dpkg -r --force-depends raspberrypi-kernel
sudo dpkg -i ./raspberrypi-kernel_<version>_arm64.deb
```

Or use the `./install-deb.sh` script, which must be in the same folder as the deb package:

```console
sudo sh install-deb.sh
```

Optionally set the raspberry pi kernel package to hold, to prevent from updating to newer official versions:

```console
apt-mark hold raspberrypi-kernel
```
After a reboot of the raspberry pi `uname -a` should print `SMP` and `PREEMPT_RT`

```console
uname -a
# Output: Linux raspberrypi <version> #1 SMP PREEMPT_RT ...
```
