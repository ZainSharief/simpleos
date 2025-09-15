bits 16         ; real mode      
org 0x7C00 

jmp short 0x5A
nop

; BIOS parameter block
oem_identifier		    db 'MSWIN4.1'
bytes_per_sector	    dw 0x0200
sectors_per_cluster	    db 0x01
reserved_sectors	    dw 0x0020
number_of_fats		    db 0x02
directory_entries	    dw 0x0000
logical_sector_count	dw 0x0000 ; overflow
media_descriptor_type	db 0xF8
sectors_per_fat		    dw 0x0000
sectors_per_track	    dw 0x0020
head_count		        dw 0x0008
hidden_sector_count	    dd 0x00000000
large_sector_count 	    dd 0x00020000

; fat32 extended boot record
sectors_per_fat_32      dd 0x000003F1
flags                   dw 0x0000
fat_version             dw 0x0000
root_cluster            dd 0x00000002
fsinfo                  dw 0x0001
backup_boot_sector      dw 0x0006
                        dd 0x00000000
                        dd 0x00000000
                        dd 0x00000000
drive_number            db 0x80 ; hard disk (set later)
                        db 0x00
boot_signature          db 0x29
volume_id               dd 0x00000000
volume_label            db 'SIMPLEOS   '
file_system_type        db 'FAT32   '

start:
    jmp main

%include 'src/bootloader/include/print.asm'

DAP:
    db 0x10                 ; size of packet = 16
    db 0x00                 ; reserved
    dw 0x0002               ; [2]  number of sectors to read
    dw 0x8000               ; [4]  offset of buffer
    dw 0x0000               ; [6]  segment of buffer
    dq 0x0000000000000002   ; [8]  64-bit LBA

load_stage_2:
    ; extended read sectors from drive
    mov si, DAP
    mov ah, 0x42
    mov dl, [drive_number]
    int 0x13
    jc .read_error
    ret

.read_error:
    ; print error message + retry
    mov si, read_error
    call print
    shr ax, 8
    call print_num
    mov si, end_string
    call print
    jmp load_stage_2

main: 
    ; sets es, ds and carry bit
    xor ax, ax
    mov es, ax
    mov ds, ax
    cli

    ; sets up stack pointer
	mov ss, ax
	mov sp, 0x7C00

    ; updates the current drive
    mov [drive_number], dl

    ; loads and jumps to bootloader stage 2
    call load_stage_2
    jmp 0x0000:0x8000

read_error db 'ERROR: Failed to read disk. Code: ', 0x00
end_string db 0x0D, 0x0A, 0x00

times 510-($-$$) db 0
dw 0xAA55 ; end magic number