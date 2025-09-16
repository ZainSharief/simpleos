ASM        := nasm
QEMU       := qemu-system-i386
BUILD_DIR  := build
SRC_DIR    := src
IMG        := $(BUILD_DIR)/disk.img
BOOT_BIN   := $(BUILD_DIR)/bootloader.bin
LOADER_BIN := $(BUILD_DIR)/loader.bin
KERNEL_BIN := $(BUILD_DIR)/kernel.bin
KERNEL_LOADER_O := $(BUILD_DIR)/kernel_loader.o
KERNEL_LOADER_BIN := $(BUILD_DIR)/kernel_loader.bin

CROSS   := ~/opt/cross/bin/i686-elf
CC      := $(CROSS)-gcc
LD      := $(CROSS)-ld
CFLAGS  := -ffreestanding -O2 -Wall -Wextra
LDFLAGS := -T linker.ld -nostdlib

.PHONY: all run clean bootloader loader kernel disk_image always

all: $(IMG)

# floppy image
disk_image: $(IMG)

$(IMG): $(BOOT_BIN) $(LOADER_BIN) $(KERNEL_LOADER_BIN) $(KERNEL_BIN) | always
	dd if=/dev/zero of=$@ bs=1M count=64 status=none
	mkfs.fat -F 32 -n "NBOS" $@

	# Write bootloader to first sector
	dd if=$(BOOT_BIN) of=$@ conv=notrunc bs=512 count=1 status=none

	# Write Loader at fixed LBA 2
	dd if=$(LOADER_BIN) of=$@ conv=notrunc bs=512 seek=2 status=none

	# Write Kernel Loader at fixed LBA 4
	dd if=$(KERNEL_LOADER_BIN) of=$@ conv=notrunc bs=512 seek=4 status=none

	# Copy loader + kernel into image using mtools
	mcopy -i $@ $(KERNEL_BIN) ::kernel.bin

# boot.asm
bootloader: $(BOOT_BIN)

$(BOOT_BIN): $(SRC_DIR)/bootloader/boot.asm | always
	$(ASM) $< -f bin -o $@

# loader.asm
loader: $(LOADER_BIN)

$(LOADER_BIN): $(SRC_DIR)/bootloader/loader.asm | always
	$(ASM) $< -f bin -o $@

# kernel_loader.c
kernel_loader: $(KERNEL_LOADER_BIN)

$(KERNEL_LOADER_BIN): $(SRC_DIR)/bootloader/kernel_loader.c | always
	$(CC) $(CFLAGS) -c $< -o $(KERNEL_LOADER_O)
	$(LD) $(LDFLAGS) -o $@ $(KERNEL_LOADER_O)

# kernel.asm
kernel: $(KERNEL_BIN)

$(KERNEL_BIN): $(SRC_DIR)/kernel/kernel.asm | always
	$(ASM) $< -f bin -o $@

# running in QEMU
run: $(IMG)
	$(QEMU) -hda $(IMG) -monitor stdio

# ensure build directory exists
always:
	@mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)/*
