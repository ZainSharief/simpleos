ASM        := nasm
QEMU       := qemu-system-i386
BUILD_DIR  := build
SRC_DIR    := src
IMG        := $(BUILD_DIR)/floppy.img
BOOT_BIN   := $(BUILD_DIR)/bootloader.bin
KERNEL_BIN := $(BUILD_DIR)/kernel.bin

.PHONY: all run clean bootloader kernel floppy_image always

all: floppy_image

# floppy image
floppy_image: $(IMG)

$(IMG): $(BOOT_BIN) $(KERNEL_BIN)
	@echo "[+] Creating floppy image..."
	dd if=/dev/zero of=$@ bs=512 count=2880 status=none
	mkfs.fat -F 12 -n "NBOS" $@
	dd if=$(BOOT_BIN) of=$@ conv=notrunc
	mcopy -o -i build/floppy.img build/kernel.bin ::kernel.bin


# bootloader
bootloader: $(BOOT_BIN)

$(BOOT_BIN): $(SRC_DIR)/bootloader/boot.asm | always
	$(ASM) $< -f bin -o $@

# kernel 
kernel: $(KERNEL_BIN)

$(KERNEL_BIN): $(SRC_DIR)/kernel/kernel.asm | always
	$(ASM) $< -f bin -o $@

# running in QEMU
run: $(IMG)
	$(QEMU) -fda $(IMG)

# ensure build directory exists
always:
	@mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)/*
