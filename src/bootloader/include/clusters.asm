; src/bootloader/include/clusters.asm

; inputs: es:bx (start of root), cluster_name (pointer to file name)
; outputs: [cluster] - starting cluster
; Requirements: 'print' function
find_cluster:

    mov di, bx
    mov cx, 0xE0 ; 14 sectors
    mov si, cluster_name
    mov al, byte [cluster_name]

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
    mov si, cluster_name
    mov al, byte [cluster_name]
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
    ret

load_clusters:

    ; root_sectors = ((directory_entries * 32) + (bytes_per_sector - 1)) / bytes_per_sector
    mov ax, 0x20 
    mul word [directory_entries]
    mov bx, [bytes_per_sector]
    dec bx
    add ax, bx
    div word [bytes_per_sector]

    ;first_sector = reserved_sectors + (number_of_fats * sectors_per_fat) + root_sectors
    add ax, word [reserved_sectors]
    mov bx, ax
    xor ax, ax 
    mov al, [number_of_fats]
    mul word [sectors_per_fat]
    add bx, ax

    mov cx, es
    call .iterate_cluster
    ret

.iterate_cluster:

    call .load_cluster
    call .find_next_cluster
    
    mov ax, [cluster]
    cmp ax, 0xFF8
    jb .iterate_cluster
    ret

; bx = first_sector (must keep this)
.load_cluster:

    ;sector = first_sector + (cluster_num - 2) * sectors_per_cluster
    mov ax, [cluster]
    sub ax, 0x0002
    xor cx, cx 
    mov cl, [sectors_per_cluster]
    mul cx
    add ax, bx

    push bx
    mov si, ax
    call lba_to_chs

    mov ah, 0x02
    mov al, [sectors_per_cluster]

    mov bx, di
    mov dl, 0x00
    int 0x13

    mov ax, [bytes_per_sector]
    xor bx, bx
    mov bl, [sectors_per_cluster]
    mul bx 
    shr ax, 0x04
    mov bx, es
    add ax, bx 
    mov es, ax

    pop bx
    ret

.find_next_cluster:

    pusha

    ; fat loaded at 0x2000:0x0000
    mov ax, 0x2000 
    mov es, ax 
    mov si, 0x0000 

    mov ax, 0x03
    mul word [cluster]

    xor dx, dx
    mov bx, 0x02
    div bx
    add si, ax
    mov ax, word [es:si]

    cmp dx, 0x00
    je .even
    
    shr ax, 0x04
    mov [cluster], ax
    jmp .end

.even:
    and ax, 0x0FFF
    mov [cluster], ax
      
.end:
    popa
    ret