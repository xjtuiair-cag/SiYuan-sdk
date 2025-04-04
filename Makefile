# Makefile for RISC-V toolchain; run 'make help' for usage.

ROOT     := $(patsubst %/,%, $(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
RISCV    ?= $(ROOT)/install
DEST     := $(abspath $(RISCV))
PATH     := $(DEST)/bin:$(PATH)

NR_CORES := $(shell nproc)

# default configure flags
gnu-toolchain-co-fast = --prefix=$(RISCV) --disable-gdb# no multilib for fast
pk-co                 = --prefix=$(RISCV) --host=riscv64-unknown-linux-gnu-elf CC=riscv64-unknown-linux-gnu-gcc OBJDUMP=riscv64-unknown-linux-gnu-objdump
tests-co              = --prefix=$(RISCV)/target

# default make flags
fesvr-mk                = -j$(NR_CORES)
isa-sim-mk              = -j$(NR_CORES)
gnu-toolchain-libc-mk   = linux -j$(NR_CORES)
pk-mk 					= -j$(NR_CORES)
tests-mk         		= -j$(NR_CORES)

# linux image
buildroot_defconfig = configs/buildroot_defconfig
linux_defconfig = configs/linux_defconfig
busybox_defconfig = configs/busybox.config

install-dir:
	mkdir -p $(RISCV)

$(RISCV)/bin/riscv64-unknown-linux-gnu-gcc: gnu-toolchain-no-multilib
	cd riscv-gnu-toolchain/build;\
	make $(gnu-toolchain-libc-mk);\
	cd $(ROOT)

gnu-toolchain-libc: $(RISCV)/bin/riscv64-unknown-linux-gnu-gcc

gnu-toolchain-no-multilib: install-dir
	mkdir -p riscv-gnu-toolchain/build
	cd riscv-gnu-toolchain/build;\
	../configure $(gnu-toolchain-co-fast);\
	cd $(ROOT)

pk: install-dir $(RISCV)/bin/riscv64-unknown-linux-gnu-gcc
	mkdir -p riscv-pk/build
	cd riscv-pk/build;\
	../configure $(pk-co);\
	make $(pk-mk);\
	make install;\
	cd $(ROOT)

all: gnu-toolchain-libc 

HelloWorld:
	cd ./Hello_world/ && $(RISCV)/bin/riscv64-unknown-linux-gnu-gcc hello_world.c -o hello_world.elf -lpthread
	cp ./Hello_world/hello_world.elf rootfs/
rootfs/2048:
	cp ./game/2048/2048.elf rootfs/
# cool command-line tetris
rootfs/tetris:
	cd ./game/vitetris/ && make clean && ./configure CC=riscv64-unknown-linux-gnu-gcc && make
	cp ./game/vitetris/tetris $@
rootfs/coremark:
	cd ./coremark/ && ./build-coremark.sh
	cp ./coremark/coremark.riscv ./rootfs/coremark.riscv
vmlinux: $(buildroot_defconfig) $(linux_defconfig) $(busybox_defconfig) $(RISCV)/bin/riscv64-unknown-linux-gnu-gcc HelloWorld rootfs/2048 rootfs/tetris rootfs/coremark
	mkdir -p build
	make -C buildroot defconfig BR2_DEFCONFIG=../$(buildroot_defconfig)
	make -C buildroot
	cp buildroot/output/images/vmlinux build/vmlinux
	cp build/vmlinux vmlinux

bbl: vmlinux
	cd build && ../riscv-pk/configure --host=riscv64-unknown-elf CC=riscv64-unknown-linux-gnu-gcc OBJDUMP=riscv64-unknown-linux-gnu-objdump --with-payload=vmlinux --enable-logo --with-logo=../configs/logo.txt
	make -C build
	cp build/bbl bbl

bbl_binary: bbl
	riscv64-unknown-elf-objcopy -O binary bbl bbl_binary

clean:
	rm -rf vmlinux bbl riscv-pk/build/vmlinux riscv-pk/build/bbl cachetest/*.elf rootfs/tetris
	make -C buildroot distclean

bbl.bin: bbl
	riscv64-unknown-elf-objcopy -S -O binary --change-addresses -0x80000000 $< $@

clean-all: clean
	rm -rf riscv-gnu-toolchain/build riscv-pk/build

.PHONY: rootfs/tetris rootfs/coremark rootfs/2048

help:
	@echo "usage: $(MAKE) [RISCV='<install/here>'] [tool/img] ..."
	@echo ""
	@echo "install [tool] to \$$RISCV with compiler <flag>'s"
	@echo "    where tool can be any one of:"
	@echo "        fesvr isa-sim gnu-toolchain tests pk"
	@echo ""
	@echo "build linux images for ariane"
	@echo "    build vmlinux with"
	@echo "        make vmlinux"
	@echo "    build bbl (with vmlinux) with"
	@echo "        make bbl"
	@echo ""
	@echo "There are two clean targets:"
	@echo "    Clean only buildroot"
	@echo "        make clean"
	@echo "    Clean everything (including toolchain etc)"
	@echo "        make clean-all"
	@echo ""
	@echo "defaults:"
	@echo "    RISCV='$(DEST)'"
