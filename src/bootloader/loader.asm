bits 16         ; real mode      
org 0x8000

jmp main

%include 'src/bootloader/include/print.asm'
%include 'src/bootloader/include/load_fat.asm'
%include 'src/bootloader/include/load_root.asm'
%include 'src/bootloader/include/find_cluster.asm'

DAP:
    db 0x10                 ; size of packet = 16
    db 0x00                 ; reserved
    dw 0x0000               ; [2]  number of sectors to read
    dw 0x0000               ; [4]  offset of buffer
    dw 0x0000               ; [6]  segment of buffer
    dq 0x0000000000000000   ; [8]  64-bit LBA

load_data:

    pusha 
    xor bx, bx
    mov es, bx
    mov bx, 0x7C00
    
    mov ax, word [es:bx+0x0B]
    mov word [bytes_per_sector], ax

    mov ax, word [es:bx+0x0E]
    mov word [reserved_sectors], ax

    mov eax, dword [es:bx+0x024]
    mov dword [sectors_per_fat_32], eax

    mov al, byte [es:bx+0x040]
    mov byte [drive_number], al

    mov al, byte [es:bx+0x10]
    mov byte [number_of_fats], al

    mov ax, word [es:bx+0x02C]
    mov word [root_cluster], ax

    mov al, byte [es:bx+0x0D]
    mov byte [sectors_per_cluster], al

    popa
    ret

enable_a20:
    push ax 
    in al, 0x92
    or al, 0x02
    out 0x92, al
    pop ax
    ret

main:
    ; sets es, ds and carry bit
    cli
    xor ax, ax
    mov es, ax
    mov ds, ax
    
    ; sets up stack pointer
	mov ss, ax
	mov sp, 0x7C00

    ; loads neccessary bpb/ebr values
    call load_data

    ; load file allocation table at 0x1000:0x0000
    call load_fat    

    ; load root directory at 0x9000:0x0000 
    call load_root

    ; locates the cluster
    mov bx, 0x9000
    mov es, bx
    xor bx, bx
    call find_cluster

    call enable_a20

    jmp $

cluster_name db "KERNEL  BIN", 0
cluster	dw 0x0000
kernel_cluster dq 0x00000000

load_fat_error db 'ERROR: Failed to read FAT. Code ', 0x00
load_root_error db 'ERROR: Failed to load Root Directory. Code ', 0x00
end_string db 0x0D, 0x0A, 0x00

bytes_per_sector        dw 0x0000
reserved_sectors	    dw 0x0000
sectors_per_fat_32      dd 0x00000000
drive_number            db 0x00
number_of_fats          db 0x00
root_cluster            dw 0x0000
sectors_per_cluster     db 0x00