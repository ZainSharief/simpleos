bits 16               ; real mode
org 0x7C00            ; load address for BIOS

jmp short start  
nop

oem_identifier		    db 'MSWIN4.1'		;8B UNUSED
bytes_per_sector	    dw 0x0200		    ;2B USED
sectors_per_cluster	    db 0x01			    ;1B USED
reserved_sectors	    dw 0x0001		    ;2B USED
number_of_fats		    db 0x02			    ;1B USED
directory_entries	    dw 0x00E0		    ;2B USED
logical_sector_count	dw 0x0B40		    ;2B UNUSED
media_descriptor_type	db 0xF0			    ;1B	0xF0 = 3.5inch floppy UNUSED
sectors_per_fat		    dw 0x0009		    ;2B USED
sectors_per_track	    dw 0x0012		    ;2B USED
head_count		        dw 0x0002		    ;2B USED
hidden_sector_count	    dd 0			    ;4B UNUSED
large_sector_count 	    dd 0			    ;4B UNUSED

; extended boot record
drive_number		    db 0			    ;1B UNUSED
			            db 0			    ;1B UNUSED
signature		        db 0x1D			    ;1B UNUSED
volume_id 		        db 12h,34h,56h,78h  ;4B	UNUSED
volume_label		    db 'SIMPLEOS   '	;11B UNUSED
system_id		        db 'FAT12   '		;8B UNUSED

start:
    jmp main

%include 'src/bootloader/include/print.asm'
%include 'src/bootloader/include/lba_to_chs.asm'
%include 'src/bootloader/include/clusters.asm'

load_root:

    mov si, 0x13
    call lba_to_chs

    mov ah, 0x02 ; read operation
    mov al, 0x0E ; read 14 sectors
    mov dl, 0x00 ; read from floppy

    ; reads root to 0x0000:0x7E00 
    mov bx, 0x0000 
    mov es, bx
    mov bx, 0x7E00 
    int 0x13
    jc load_root
    ret

load_fat:
    pusha

    mov si, 0x01   
    call lba_to_chs

    ; read to 0x2000:0x0000
    mov ax, 0x2000
    mov es, ax 
    xor bx, bx  

    mov ah, 0x02     
    mov al, [sectors_per_fat]

    mov dl, 0x00
    int 0x13

    popa
    ret

main: 
    mov ax, 0
	mov ds, ax
	mov es, ax

    ; sets up stack pointer
    mov ax, 0x9000
	mov ss, ax
	mov sp, 0xFFFF

    call load_root
    call find_cluster
    call load_fat
    
    mov bx, 0x0000
    mov es, bx
    mov di, 0x9A00
    call load_clusters

    jmp 0x0000:0x9A00
    
cluster_name db "LOADER  BIN", 0
cluster	dw 0x0000

times 510-($-$$) db 0
dw 0xAA55               ; gotta end with this magic number