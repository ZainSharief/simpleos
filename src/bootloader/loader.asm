bits 16               ; real mode
org 0x9A00            ; load address for BIOS

jmp short start
nop

; disk information
bytes_per_sector	    dw 0x0200		    ;2B USED
sectors_per_cluster	    db 0x01			    ;1B USED
reserved_sectors	    dw 0x0001		    ;2B USED
number_of_fats		    db 0x02			    ;1B USED
directory_entries	    dw 0x00E0		    ;2B USED
sectors_per_fat		    dw 0x0009		    ;2B USED
sectors_per_track	    dw 0x0012		    ;2B USED
head_count		        dw 0x0002		    ;2B USED

start:
    jmp main

%include 'src/bootloader/include/print.asm'
%include 'src/bootloader/include/lba_to_chs.asm'
%include 'src/bootloader/include/clusters.asm'

enable_a20:
    push ax 
    in al, 0x92
    or al, 0x02
    out 0x92, al
    pop ax
    ret

gdt_start:
    dq 0x0000000000000000        ; null descriptor

    ; code descriptor: base=0, limit=4GB, access=0x9A, gran=0xCF
    db 0xFF,0xFF,0x00,0x00,0x00,0x9A,0xCF,0x00

    ; data descriptor: base=0, limit=4GB, access=0x92, gran=0xCF
    db 0xFF,0xFF,0x00,0x00,0x00,0x92,0xCF,0x00

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1   ; size - 1
    dd gdt_start                 ; base

main: 
    mov ax, 0x9000
	mov ss, ax
	mov sp, 0xFFFF

    xor bx, bx
    mov es, bx
    mov ds, bx
    mov bx, 0x7E00
    call find_cluster

    mov bx, 0x1000
    mov es, bx
    mov di, 0x0000
    call load_clusters

    cli
    call enable_a20
    lgdt [gdt_descriptor]

    mov eax, cr0
    or  eax, 1
    mov cr0, eax

    jmp 0x08:pm_entry_32

bits 32
pm_entry_32:
    ; set data selectors to 0x10
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; set up stack 
    mov esp, 0x00090000     

    ; jump to kernel physical address 
    mov eax, 0x10000
    jmp eax
    
cluster_name db "KERNEL  BIN", 0
cluster	dw 0x0000