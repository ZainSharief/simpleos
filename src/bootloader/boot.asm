bits 16               ; real mode
org 0x7C00            ; load address for BIOS

jmp short start  
nop

oem_identifier		    db 'MSWIN4.1'		;8B
bytes_per_sector	    dw 0x0200		    ;2B
sectors_per_cluster	    db 0x01			    ;1B 
reserved_sectors	    dw 0x0001		    ;2B
number_of_fats		    db 0x02			    ;1B
directory_entries	    dw 0x00E0		    ;2B
logical_sector_count	dw 0x0B40		    ;2B
media_descriptor_type	db 0xF0			    ;1B	0xF0 = 3.5inch floppy
sectors_per_fat		    dw 0x0009		    ;2B
sectors_per_track	    dw 0x0012		    ;2B
head_count		        dw 0x0002		    ;2B
hidden_sector_count	    dd 0			    ;4B
large_sector_count 	    dd 0			    ;4B

; extended boot record
drive_number		    db 0			    ;1B
			            db 0			    ;1B
signature		        db 0x1D			    ;1B
volume_id 		        db 12h,34h,56h,78h  ;4B	
volume_label		    db 'SIMPLEOS   '	;11B
system_id		        db 'FAT12   '		;8B

%define ENDSTRING 0x00

start:
    call main

load_root:

    ; cylinder = LBA / (heads * sectors_per_track)
    mov ax, [head_count]
    mul word [sectors_per_track]
    mov bx, ax
    mov ax, 0x13
    xor dx, dx
    div bx
    mov ch, al ; cylinder                 

    ; temp = LBA % (heads * sectors_per_track)
    mov ax, 0x13
    xor dx, dx
    div bx
    mov ax, dx

    ; head = temp / sectors_per_track
    xor dx, dx
    div word [sectors_per_track]
    mov dh, al ; head

    ; sector = (temp % sectors_per_track) + 1
    mov ax, dx
    add ax, 0x01
    mov cl, al ; sector

    mov ah, 0x02 ; read sectors
    mov al, 0x0E ; read 14 sectors

    mov dl, 0x00 ; drive

    ; start reading to 0x0000:0x7E00
    mov bx, 0x0000 
    mov es, bx
    mov bx, 0x7E00 
    stc
    int 0x13          

    jc load_root
    mov si, message
    call print
    jmp $

; prints string at SI
print:
    push ax

.print_loop:
    lodsb             ; byte from SI -> AL, increment SI
    cmp al, 0         ; check if end of string
    je .end_print
    mov ah, 0x0E      ; tells to print character in AL
    int 0x10          ; print interrupt
    jmp .print_loop
    
.end_print:
    pop ax
    ret               ; loop forever

main: 

    mov ax, 0
	mov ds, ax
	mov es, ax

	mov ss, ax
	mov sp, 0x7C00

    call load_root

message db "Worked!", ENDSTRING
kernel_path db "KERNEL  BIN", ENDSTRING

times 510-($-$$) db 0
dw 0xAA55               ; gotta end with this magic number
