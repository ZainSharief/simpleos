ASM        := nasm
QEMU       := qemu-system-i386
BUILD_DIR  := build
SRC_DIR    := src
IMG        := $(BUILD_DIR)/floppy.img
BOOT_BIN   := $(BUILD_DIR)/bootloader.bin
LOADER_BIN := $(BUILD_DIR)/loader.bin
KERNEL_BIN := $(BUILD_DIR)/kernel.bin

.PHONY: all run clean bootloader loader kernel floppy_image always

all: $(IMG)

# floppy image
floppy_image: $(IMG)

$(IMG): $(BOOT_BIN) $(LOADER_BIN) $(KERNEL_BIN) | always
	dd if=/dev/zero of=$@ bs=512 count=2880 status=none

	mkfs.fat -F 12 -n "NBOS" $@

	# Write bootloader to first sector
	dd if=$(BOOT_BIN) of=$@ conv=notrunc bs=512 count=1 status=none

	# Copy loader + kernel into image using mtools
	mcopy -i $@ $(LOADER_BIN) ::loader.bin
	mcopy -i $@ $(KERNEL_BIN) ::kernel.bin

# bootloader
bootloader: $(BOOT_BIN)

$(BOOT_BIN): $(SRC_DIR)/bootloader/boot.asm | always
	$(ASM) $< -f bin -o $@

# loader
loader: $(LOADER_BIN)

$(LOADER_BIN): $(SRC_DIR)/bootloader/loader.asm | always
	$(ASM) $< -f bin -o $@

# kernel 
kernel: $(KERNEL_BIN)

$(KERNEL_BIN): $(SRC_DIR)/kernel/kernel.asm | always
	$(ASM) $< -f bin -o $@

# running in QEMU
run: $(IMG)
	$(QEMU) -fda $(IMG) -monitor stdio

# ensure build directory exists
always:
	@mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)/*
