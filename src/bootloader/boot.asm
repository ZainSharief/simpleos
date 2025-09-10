bits 16         ; real mode               
org 0x7C00            

jmp short 0x5A
nop

; BIOS parameter block
oem_identifier		    db 'MSWIN4.1'		;8B 
bytes_per_sector	    dw 0x0200		    ;2B 
sectors_per_cluster	    db 0x08			    ;1B 
reserved_sectors	    dw 0x0020		    ;2B 
number_of_fats		    db 0x02			    ;1B 
directory_entries	    dw 0    		    ;2B 
logical_sector_count	dw 0    		    ;2B 
media_descriptor_type	db 0xF8			    ;1B	
sectors_per_fat		    dw 0    		    ;2B 
sectors_per_track	    dw 0x003F		    ;2B 
head_count		        dw 0x00FF		    ;2B 
hidden_sector_count	    dd 0       			;4B 
large_sector_count 	    dd 0x10000			;4B 

; fat32 extended boot record
fat_size_32             dd 100              ;4B 
flags                   dw 0                ;2B
fat_version             dw 0                ;2B
root_cluster            dd 0x02             ;4B   
fsinfo                  dw 0x01             ;2B
backup_boot_sector      dw 0x06             ;2B
reserved                times 12 db 0       ;12B
drive_number            db 0                ;1B
reserved1               db 0                ;1B
boot_signature          db 0x29             ;1B
volume_id               dd 0x12345678       ;4B
volume_label            db 'SIMPLEOS   '    ;11B
file_system_type        db 'FAT32   '       ;8B

start:
    jmp main

DAP:
    db 0x10              ; size of packet = 16
    db 0x00              ; reserved
    dw 0                 ; [2]  number of sectors to read
    dw 0                 ; [4]  offset of buffer
    dw 0                 ; [6]  segment of buffer
    dq 0                 ; [8]  64-bit LBA

load_root:

    ; first_data_sector = reserved_sectors + (number_of_fats * fat_size_32)
    mov eax, [fat_size_32]
    movzx ebx, byte [number_of_fats]
    mul ebx 
    movzx ebx, word [reserved_sectors]
    add ebx, eax

    ; cluster_sector = first_data_sector + (cluster_num - 2) * sectors_per_cluster
    mov eax, [root_cluster]
    dec eax
    dec eax
    movzx ecx, byte [sectors_per_cluster]
    mul ecx 
    add eax, ebx

    mov [DAP+2], word 0x01
    mov [DAP+4], word 0x7E00
    mov [DAP+6], word 0x0000
    mov [DAP+8], eax

    mov si, DAP        
    mov ah, 0x42       
    mov dl, [drive_number]  ; BIOS drive number (0x80 = first hard disk)
    int 0x13
    jc load_root    ; if carry set, error
    ret

main: 
    mov [drive_number], dl

    mov ax, 0
	mov ds, ax
	mov es, ax

    ; sets up stack pointer
    mov ax, 0x9000
	mov ss, ax
	mov sp, 0xFFFF

    call load_root
    
cluster_name db "LOADER  BIN", 0
cluster	dd 0x00000000

times 510-($-$$) db 0
dw 0xAA55               ; gotta end with this magic number