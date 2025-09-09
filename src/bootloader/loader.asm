bits 16               ; real mode
org 0x9A00            ; load address for BIOS

start:
    jmp main

; inputs: es:bx
; outputs: [cluster] - starting cluster
find_kernel:

    mov di, bx
    mov cx, 0xE0 ; 14 sectors
    mov si, kernel_name
    mov al, byte [kernel_name]

    call .compare_sector
    cmp al, 0x00
    je .error_search
    ret

.compare_sector:

    push di
    push cx
    mov cx, 0x0B
    call .compare_word
    pop cx
    pop di

    cmp al, 0x01
    je .success

    call .increment_sector

    dec cx
    cmp cx, 0x00 
    jne .compare_sector
    mov al, 0x00
    ret

.increment_sector:
    mov si, kernel_name
    mov al, byte [kernel_name]
    add di, 0x20
    ret

.compare_word:
    
    cmp al, [es:di]
    jne .failure 

    call .increment_letter

    dec cx
    cmp cx, 0x00
    jne .compare_word
    mov al, 0x01
    ret

.increment_letter:
    inc si
    mov al, [si]
    add di, 0x01
    ret

.success:
    mov ax, [es:di+0x1A]
    mov [cluster], ax
    mov al, 0x01
    ret

.failure:
    mov al, 0x00 
    ret

.error_search:
    mov si, error_search_text
    call print
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

print_num:
    pusha                ; save registers

    mov ax, si           ; move number to AX
    mov cx, 0            ; digit count
    mov bx, 10           ; divisor for decimal

    cmp ax, 0
    jne .convert_loop
    mov al, '0'
    mov ah, 0x0E
    int 0x10
    jmp .done

.convert_loop:
    xor dx, dx           ; clear DX for DIV
    div bx               ; AX / 10 -> AX = quotient, DX = remainder
    push dx              ; save remainder
    inc cx
    cmp ax, 0
    jne .convert_loop

.print_digits:
    pop dx
    add dl, '0'          ; convert 0-9 -> ASCII
    mov ah, 0x0E
    mov al, dl
    int 0x10
    loop .print_digits

.done:
    mov al, 0x00 
    mov ah, 0x0E
    int 0x10
    popa
    ret

; prints string at SI
print:
    pusha

.print_loop:
    lodsb             ; byte from SI -> AL, increment SI
    cmp al, 0         ; check if end of string
    je .end_print
    mov ah, 0x0E      ; tells to print character in AL
    int 0x10          ; print interrupt
    jmp .print_loop
    
.end_print:
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

    call find_kernel  
    call load_kernel

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
    
kernel_name db "KERNEL  BIN", 0
cluster	dw 0x0000

error_search_text db "ERROR: Unable to Locate Kernel", 0

; disk information
bytes_per_sector	    dw 0x0200		    ;2B USED
sectors_per_cluster	    db 0x01			    ;1B USED
reserved_sectors	    dw 0x0001		    ;2B USED
number_of_fats		    db 0x02			    ;1B USED
directory_entries	    dw 0x00E0		    ;2B USED
sectors_per_fat		    dw 0x0009		    ;2B USED
sectors_per_track	    dw 0x0012		    ;2B USED
head_count		        dw 0x0002		    ;2B USED