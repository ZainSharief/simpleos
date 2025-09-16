; include/bootloader/find_cluster.asm

; inputs: es:bx (start of root), cluster_name (pointer to file name)
; outputs: [cluster] - starting cluster
; Requirements: 'print' function
find_cluster:

    mov di, bx
    mov si, cluster_name
    mov al, byte [cluster_name]

    call .compare_sector
    cmp al, 0x00
    je .error_search
    ret

.compare_sector:

    push di
    mov cx, 0x0B
    call .compare_word
    pop di

    cmp al, 0x01
    je .success

    call .increment_sector

    jmp .compare_sector
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
    movzx eax, word [es:di+0x20]
    shl eax, 16
    mov ax, [es:di+0x1A]
    mov [cluster], eax
    mov al, 0x01
    ret

.failure:
    mov al, 0x00 
    ret

.error_search:
    ret