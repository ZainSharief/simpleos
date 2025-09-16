bits 16         ; real mode      
org 0x8000

jmp main

bpb_info:
    .bytes_per_sector        dw 0x0000
    .sectors_per_cluster     db 0x00
    .reserved_sectors	     dw 0x0000
    .number_of_fats          db 0x00
    .sectors_per_fat_32      dd 0x00000000
    .root_cluster            dd 0x00000000
    .drive_number            db 0x00

%include 'include/bootloader/print.asm'
%include 'include/bootloader/load_fat.asm'
%include 'include/bootloader/load_root.asm'
%include 'include/bootloader/find_cluster.asm'

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
    mov word [bpb_info.bytes_per_sector], ax

    mov al, byte [es:bx+0x0D]
    mov byte [bpb_info.sectors_per_cluster], al

    mov ax, word [es:bx+0x0E]
    mov word [bpb_info.reserved_sectors], ax

    mov al, byte [es:bx+0x10]
    mov byte [bpb_info.number_of_fats], al

    mov eax, dword [es:bx+0x24]
    mov dword [bpb_info.sectors_per_fat_32], eax

    mov eax, dword [es:bx+0x2C]
    mov dword [bpb_info.root_cluster], eax
    
    mov al, byte [es:bx+0x40]
    mov byte [bpb_info.drive_number], al
    popa
    ret

load_kernel_loader:
    pusha

    mov ax, 0x0010
    mov di, 0x8400
    xor bx, bx
    mov es, bx
    mov bx, 0x0004

    mov [DAP+2], ax    
    mov [DAP+4], di
    mov [DAP+6], es
    mov word [DAP+8], bx
    mov word [DAP+10], 0x0000
    mov dword [DAP+12], 0x00000000

    mov si, DAP
    mov ah, 0x42
    mov dl, [bpb_info.drive_number]
    int 0x13

    popa
    ret

enable_a20:
    push ax 
    in al, 0x92
    or al, 0x02
    out 0x92, al
    pop ax
    ret

gdt_start:
    dq 0x0000000000000000

gdt_code:
    dw 0xFFFF      ; limit low
    dw 0x0000      ; base low
    db 0x00        ; base middle
    db 10011010b   ; code segment, present, ring 0, executable, readable
    db 11001111b   ; granularity: 4K, 32-bit
    db 0x00        ; base high

gdt_data:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10010010b   ; data segment, present, ring 0, writable
    db 11001111b
    db 0x00

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

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

    ; loads the C code to load the kernel
    call load_kernel_loader

    call enable_a20
    lgdt [gdt_descriptor]

    ; enable protected mode
    mov eax, cr0
    or  eax, 1
    mov cr0, eax

    jmp 0x08:protected_entry

cluster_name db "KERNEL  BIN", 0
cluster	dd 0x00000000

load_fat_error db 'ERROR: Failed to read FAT. Code ', 0x00
load_root_error db 'ERROR: Failed to load Root Directory. Code ', 0x00
end_string db 0x0D, 0x0A, 0x00

; protected mode entry-point.
bits 32
protected_entry:
    ; set data selectors to 0x10
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    ; set up stack 
    mov ss, ax
    mov esp, 0x90000

    ; call c load_kernel 
    push bpb_info
    push dword [cluster]
    call 0x8400
    
    ; clean up the stack
    add esp, 8

    ; jump to kernel
    mov eax, 0x100000
    jmp eax