; src/bootloader/include/load_root.asm

; input: [cluster]
; outputs: bx = lba 
cluster_to_lba:

    push ax
    push cx

    ; first_data_sector = reserved_sectors + (number_of_fats * sectors_per_fat_32)
    movzx ax, byte [number_of_fats]
    mov ebx, [sectors_per_fat_32]
    mul bx 
    mov bx, [reserved_sectors]
    add bx, ax

    ; lba = first_data_sector + ((root_cluster - 2) * sectors_per_cluster)
    mov ax, [cluster]
    sub ax, 0x02
    movzx cx, byte [sectors_per_cluster]
    mul cx
    add bx, ax

    pop cx
    pop ax
    ret

load_root: 
    
    push ds
    pusha

    mov ax, [root_cluster]
    mov [cluster], ax
    call cluster_to_lba

    mov ax, 0x01
    mov di, 0x9000
    mov es, di
    xor di, di

    call .iterate_cluster
    popa
    pop ds
    ret
    
.iterate_cluster:

    call .read_memory

    mov bx, 0x1000
    mov ds, bx
    mov bx, [cluster]
    shl bx, 2
    mov bx, [bx]

    call cluster_to_lba

    mov ecx, dword [ds:bx]

    cmp ecx, 0x0FFFFFEF
    jle .iterate_cluster
    ret

.read_memory:

    mov word [DAP+2], ax
    mov word [DAP+4], di
    mov word [DAP+6], es
    mov word [DAP+8], bx
    mov word [DAP+10], 0x0000
    mov dword [DAP+12], 0x00000000

    push ax
    mov si, DAP        
    mov ah, 0x42       
    mov dl, [drive_number]
    int 0x13

    mov dx, ax
    pop ax
    jc .load_root_error
    ret

.load_root_error:
    mov si, load_root_error
    call print
    push ax
    shr dx, 8
    mov ax, dx
    call print_num
    pop ax
    mov si, end_string
    call print

    popa
    pop ds
    jmp load_root