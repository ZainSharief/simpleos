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

%define ENDSTRING 0x0D, 0x0A, 0x00

start:
    call main

load_root:

    mov si, 0x13
    call lba_to_chs

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
    ;ret

; returns with cluster pointing to kernel first cluster and si to file size in bytes
find_kernel:

    mov di, bx

    call .find_loop
    mov ax, [di+0x1A]
    mov [cluster], ax
    ; [cluster] is the first cluster of the kernel file

    mov si, [di+0x1C]
    ret

.find_loop:

    mov si, kernel_name
    mov cl, 0x00

    push di
    call .compare_loop
    pop di

    cmp ax, 0x01
    je .found

    add di, 0x20
    jmp .find_loop

.compare_loop:
    
    lodsb          
    cmp al, [es:di]   
    jne .not_found
    inc di

    inc cl
    cmp cl, 0x0B
    jne .compare_loop
    jmp .found

.found:
    mov ax, 0x01
    ret

.not_found:
    mov ax, 0x00
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
    ;ret

load_kernel:

    ;RootDirSectors = ( (DirectoryEntries * 32) + (BytesPerSector - 1) ) / BytesPerSector
    push ax
    mov cx, 0x20
    mov ax, [directory_entries]
    mul cx
    mov cx, ax
    pop ax

    mov bx, [bytes_per_sector]
    dec bx

    push ax
    add cx, bx
    mov ax, cx
    div word [bytes_per_sector]
    mov cx, ax
    pop ax

    ;FirstDataSector = ReservedSectors + (NumberOfFATs * SectorsPerFAT) + RootDirSectors
    push ax
    xor ax, ax 
    mov al, [number_of_fats]
    mul word [sectors_per_fat]
    add ax, word [reserved_sectors]
    add ax, cx
    mov dx, ax
    pop ax

    mov bx, 0x1000
    mov es, bx
    mov cx, bx
    mov di, 0x0000
    call .iterate_cluster
    ret

.iterate_cluster:

    call .load_cluster
    call .find_next_cluster
    
    mov ax, [cluster]
    cmp ax, 0xFF8
    jb .iterate_cluster
    ret

.load_cluster:

    ;Sector = FirstDataSector + (ClusterNumber - 2) * SectorsPerCluster
    push ax
    push dx
    mov ax, [cluster]
    sub ax, 0x0002
    xor dx, dx
    mov dl, [sectors_per_cluster]
    mul dx
    pop dx
    add ax, dx

    push es
    mov es, cx

    push dx
    push cx
    push bx
    mov si, ax
    call lba_to_chs ; sets ch, dh, cl
    pop bx

    mov ah, 0x02
    mov al, [sectors_per_cluster]

    mov bx, di
    mov dl, 0x00
    int 0x13
    pop cx

    mov ax, [bytes_per_sector]    
    xor dx, dx
    mov dl, [sectors_per_cluster]
    mul dx                        
    shr ax, 4                     
    add cx, ax

    pop dx
    pop es
    pop ax
    ret

.find_next_cluster:

    pusha

    ; fat loaded at 0x2000:0x0000
    mov ax, 0x2000
    mov es, ax 
    mov si, 0x0000

    mov ax, [cluster]  
    mov bx, 0x03
    mul bx
    mov bx, 0x02
    xor dx, dx
    div bx
    add si, ax
      
    mov al, [es:si]            
    mov ah, [es:si+1]

    cmp dx, 0x00
    je .even
    jmp .odd

.even:
    and ax, 0x0FFF
    mov [cluster], ax
    popa
    ret

.odd:
    shr ax, 0x04
    mov [cluster], ax
    popa
    ret

; expects lba in si -> returns ch = cylinder, dh = head, cl = sector
; MAKE SURE TO SAVE REGISTERS BEFORE CALLING
lba_to_chs:

    ; cylinder = LBA / (heads * sectors_per_track)
    mov ax, [head_count]
    mul word [sectors_per_track]
    mov cx, ax
    mov ax, si
    xor dx, dx
    div cx
    mov ch, al ; cylinder

    mov bx, dx ; temp

    ; head = temp / sectors_per_track
    mov ax, bx
    xor dx, dx
    div word [sectors_per_track]
    push ax

    ; sector = (temp % sectors_per_track) + 1
    mov ax, dx
    add ax, 0x01
    mov cl, al ; sector
    pop ax

    mov dh, al ; head
    ret

print: 
    pusha ; save registers 
    mov ax, si ; move number to AX 
    mov cx, 0 ; digit count 
    mov bx, 10 

    ; divisor for decimal 
    cmp ax, 0 
    jne .convert_loop 
    
    ; if number is 0, just print '0' 
    mov al, '0' 
    mov ah, 0x0E 
    int 0x10 
    jmp .done 
    
.convert_loop: 
    xor dx, dx ; clear DX for DIV 
    div bx ; AX / 10 -> AX = quotient, DX = remainder 
    push dx ; save remainder 
    inc cx 
    cmp ax, 0 
    jne .convert_loop 
    
.print_digits: 
    pop dx 
    add dl, '0' ; convert 0-9 -> ASCII 
    mov ah, 0x0E 
    mov al, dl 
    int 0x10 
    loop .print_digits 
    
.done: 

    mov al, " "
    mov ah, 0x0E 
    int 0x10

    popa 
    ret

main: 
    mov ax, 0
	mov ds, ax
	mov es, ax

    ; sets up stack pointer
	mov ss, ax
	mov sp, 0x7C00

    call load_root
    ;call find_kernel  
    call load_fat
    ;call load_kernel

    jmp 0x1000:0x0000
    
kernel_name db "KERNEL  BIN", 0
cluster	dw 0x0000

times 510-($-$$) db 0
dw 0xAA55               ; gotta end with this magic number
