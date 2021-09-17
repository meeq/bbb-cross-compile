# bbb-cross-compile

Docker container and runner to cross-compile code for [BeagleBone Black](https://beagleboard.org/black).

`bbb-cross-compile` will download the cross-compiler SDKs and install them inside a container.
No need to install CCStudio or build everything on-device!

## Installation

1. **Prerequisites:** You will need `docker`, `make`, `bash`, and `git` on your host machine.
  * You are on your own to satisfy these dependencies.
2. Clone this repository:
  * `git clone git@github.com:meeq/bbb-cross-compile.git`
3. Symlink the `bbb-cross-compile` script into `/usr/bin` (or somewhere else in your `PATH`):
  * `sudo ln -s $HOME/Projects/bbb/bbb-cross-compile /usr/bin/bbb-cross-compile`
4. Test the command:
  * `bbb-cross-compile --help`

## Usage

### GCC ARM

The ARM SDK is for building Linux, kernel modules, and userland programs
using the open source GNU GCC cross-compiler.

```
bbb-cross-compile --sdk gcc-arm -- make
```

#### Compiling Kernel Drivers

Clone the kernel source, check out the desired version, and cross-compile the kernel:

```sh
git clone https://github.com/beagleboard/linux
cd linux
git checkout -b ${TARGET_LINUX_KERNEL_VERSION}
bbb-cross-compile --sdk gcc-arm -- make bb.org_defconfig
bbb-cross-compile --sdk gcc-arm -- make LOADADDR=0x80000000 uImage dtbs
bbb-cross-compile --sdk gcc-arm -- make modules
```

In your kernel driver project, set the `KERNEL_DIR` environment variable to the
cloned repository with the built kernel modules, and use `--kdir` in the options:

```sh
KERNEL_DIR="$HOME/Projects/bbb/linux" bbb-cross-compile --sdk gcc-arm --kdir -- make
```

### GCC PRU

The GCC PRU SDK is for building firmware for the programmable real-time unit
using the open source GNU GCC 10+ PRU cross-compiler.

```
bbb-cross-compile --sdk gcc-pru -- make
```

### TI PRU

The TI PRU SDK is for building firmware for the programmable real-time unit
using the Texas Instruments PRU Code Generation Tools cross-compiler.

```
bbb-cross-compile --sdk ti-pru -- make
```
