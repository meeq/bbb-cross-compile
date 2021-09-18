# bb-cross-compile

Docker container and runner to cross-compile code for [BeagleBoard devices](https://beagleboard.org/).

`bb-cross-compile` will download the cross-compiler SDKs and install them inside a container.
No need to install CCStudio or build everything on-device!

## Installation

### Prerequisites

You will need `docker`, `make`, `bash`, and `git` on your host POSIX machine.

### Clone this repository

```sh
git clone git@github.com:meeq/bb-cross-compile.git
```

### Install

```sh
cd bb-cross-compile
# Install to /usr/bin
sudo make install
# OR somewhere else on your PATH
make install INSTALL_DIR=$HOME/bin
```

### Test the symlink

```sh
bb-cross-compile --help
```

## Uninstallation

```sh
# Using the same INSTALL_DIR from the Install step above...
COMMAND_SYMLINK=$INSTALL_DIR/bb-cross-compile
REPOSITORY=$(dirname $(readlink -f "$COMMAND_SYMLINK"))
# Delete the installed command
rm "$COMMAND_SYMLINK"
# Clean the repository
pushd "$REPOSITORY" && make clean && popd
# Delete the repository
rm -r "$REPOSITORY"
```

## Usage

### GCC ARM

The ARM SDK is for building Linux, kernel modules, and userland programs
using the open source GNU GCC cross-compiler.

```
bb-cross-compile --sdk gcc-arm -- make
```

#### Compiling Kernel Drivers

Clone the kernel source, check out the desired version, and cross-compile the kernel:

```sh
git clone https://github.com/beagleboard/linux
cd linux
git checkout -b ${TARGET_LINUX_KERNEL_VERSION}
bb-cross-compile --sdk gcc-arm -- make bb.org_defconfig
bb-cross-compile --sdk gcc-arm -- make LOADADDR=0x80000000 uImage dtbs
bb-cross-compile --sdk gcc-arm -- make modules
```

In your kernel driver project, set the `BB_KERNEL_DIR` environment variable to the
cloned repository with the built kernel modules, and use `--kdir` in the options:

```sh
BB_KERNEL_DIR="$HOME/Projects/linux" bb-cross-compile --sdk gcc-arm --kdir -- make
```

### GCC PRU

The GCC PRU SDK is for building firmware for the programmable real-time unit
using the open source GNU GCC 10+ PRU cross-compiler.

```
bb-cross-compile --sdk gcc-pru -- make
```

### TI PRU

The TI PRU SDK is for building firmware for the programmable real-time unit
using the Texas Instruments PRU Code Generation Tools cross-compiler.

```
bb-cross-compile --sdk ti-pru -- make
```
