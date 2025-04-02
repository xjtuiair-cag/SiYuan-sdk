# SiYuan SDK
This repository is originally from cva6-sdk, we add some new features to it.

This repository houses a set of RISCV tools.

Included tools:
* [riscv-pk](https://github.com/riscv/riscv-pk/), which contains `bbl`, a boot loader for Linux and similar OS kernels, and `pk`, a proxy kernel that services system calls for a target-machine application by forwarding them to the host machine
* [riscv-gnu-toolchain](https://github.com/riscv/riscv-gnu-toolchain), the cross compilation toolchain for riscv targets

## Quickstart

Requirements Ubuntu:
```console
$ sudo apt-get install autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev libusb-1.0-0-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev device-tree-compiler pkg-config libexpat-dev
```

Requirements Fedora:
```console
$ sudo dnf install autoconf automake @development-tools curl dtc libmpc-devel mpfr-devel gmp-devel libusb-devel gawk gcc-c++ bison flex texinfo gperf libtool patchutils bc zlib-devel expat-devel
```

Then install the tools with

```console
$ git submodule update --init --recursive
$ export RISCV=/path/to/install/riscv/toolchain # default: ./install
$ make all
```

## Environment Variables

Add `$RISCV/bin` to your path in order to later make use of the installed tools and permanently export `$RISCV`. 

Example for `.bashrc` or `.zshrc`:
```bash
$ export RISCV=/opt/riscv
$ export PATH=$PATH:$RISCV/bin
```

## Linux
You can also build a compatible linux image with bbl that boots linux:
```bash
$ make vmlinux # make only the vmlinux image
# outputs a vmlinux file in the top directory
$ make bbl.bin # generate the entire bootable image
# outputs bbl and bbl.bin
```

### Booting from an SD card
The bootloader requires a GPT partition table so you first have to create one with gdisk.

```bash
$ sudo fdisk -l # search for the corresponding disk label (e.g. /dev/sdb)
$ sudo sgdisk --clear --new=1:2048:67583 --new=2 --typecode=1:3000 --typecode=2:8300 /dev/sdb # create a new gpt partition table and two partitions: 1st partition: 32mb (ONIE boot), second partition: rest (Linux root)
```

Now you have to compile the linux kernel:
```bash
$ make bbl.bin # generate the entire bootable image
```

Then the bbl+linux kernel image can get copied to the sd card with `dd`. __Careful:__  use the same disk label that you found before with `fdisk -l` but with a 1 in the end, e.g. `/dev/sdb` -> `/dev/sdb1`.
```bash
$ sudo dd if=bbl.bin of=/dev/sdb1 status=progress oflag=sync bs=1M
```

# Coremark
We use coremark to measure the performance of single core of SiYuan. When you successfully boot linux, you will see a executable file named `coremark.riscv`. Please use `./coremark.riscv` to run it, and you will get the result like this:

```bash
#./coremark.riscv
2K Performance run parameters for coremark.
CoreMark Size: 666
Total ticks: 15557
Iterations/Sec: 33 
Total time (secs): 15
Compiler version: GCC8.2.0
Compiler flags: -O2 -static
Memory location: Please put data memory location here (e.g., code in flash, data on heap etc)
seedcrc: 0xe9f5
[0]crclist: 0xe714
[0]crcmatrix: 0xfd7
[0]crcstate: 0x85a3
[0]crcfinal: 0x2555
```
The clock frequency of SiYuan is 50M, and SiYuan run 33 iterations/sec, so the performance of SiYuan is 33/50=0.66 coremark/M.