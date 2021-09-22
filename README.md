# beaglebone-cross-compile

Docker container and runner to cross-compile code for [BeagleBone devices](https://beagleboard.org/bone).

`beaglebone-cross-compile` will download the cross-compiler SDKs and install them inside a container.
No need to install CCStudio or build everything on-device!

## Installation

### Prerequisites

Your host POSIX machine will need:

* bash (tested with 5.1.8)
* curl (tested with 7.79.0)
* docker (tested with 20.10.8)
* git (tested with 2.33.0)
* make (tested with GNU Make 4.3)

### Clone this repository

```sh
git clone git@github.com:meeq/beaglebone-cross-compile.git
```

### Install

```sh
cd beaglebone-cross-compile
# Install to /usr/bin
sudo make install
# OR somewhere else on your PATH
make install INSTALL_DIR=$HOME/bin
```

### Test the symlink

```sh
beaglebone-cross-compile --help
```

## Uninstallation

```sh
# Using the same INSTALL_DIR from the Install step above...
COMMAND_RUNNER_SYMLINK=$INSTALL_DIR/beaglebone-cross-compile
REPOSITORY=$(dirname $(readlink -f "$COMMAND_RUNNER_SYMLINK"))
# Run the clean command
"$COMMAND_RUNNER_SYMLINK" clean
# Delete the installed command runner
rm "$COMMAND_RUNNER_SYMLINK"
# Delete the cloned repository
rm -r "$REPOSITORY"
```

## Usage

### GCC ARM

The ARM SDK is for building Linux, kernel modules, and userland programs
using the open source GNU GCC cross-compiler.

```sh
beaglebone-cross-compile --sdk gcc-arm -- make
```

#### Compiling Kernel Drivers

Clone the kernel source, check out the desired version, and cross-compile the kernel:

```sh
git clone https://github.com/beagleboard/linux
cd linux
git checkout -b ${TARGET_LINUX_KERNEL_VERSION}
beaglebone-cross-compile --sdk gcc-arm -- make bb.org_defconfig
beaglebone-cross-compile --sdk gcc-arm -- make LOADADDR=0x80000000 uImage dtbs
beaglebone-cross-compile --sdk gcc-arm -- make modules
```

In your kernel driver project, set the `BEAGLEBONE_KERNEL_DIR` environment variable to the
cloned repository with the built kernel modules, and use `--kdir` in the options:

```sh
BEAGLEBONE_KERNEL_DIR="$HOME/Projects/linux" beaglebone-cross-compile --sdk gcc-arm --kdir -- make
```

### GCC PRU

The GCC PRU SDK is for building firmware for the programmable real-time unit
using the open source GNU GCC 10+ PRU cross-compiler.

```sh
beaglebone-cross-compile --sdk gcc-pru -- make
```

### TI PRU

The TI PRU SDK is for building firmware for the programmable real-time unit
using the Texas Instruments PRU Code Generation Tools cross-compiler.

```sh
beaglebone-cross-compile --sdk ti-pru -- make
```
