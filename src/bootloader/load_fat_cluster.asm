; src/bootloader/load_fat_cluster.asm

; inputs: es:di, cluster
; outputs: fat table loaded at 0x1000:0x0000
load_fat_cluster:
    pushad

    ; fat_offset = cluster * 4
    mov eax, [cluster]
    mov ebx, 0x04
    mul ebx
    mov ebx, eax

    ; fat_sector = reserved_sectors + (fat_offset / bytes_per_sector);
    movzx ecx, word [bpb_info.bytes_per_sector]
    div ecx 
    add eax, [bpb_info.reserved_sectors]
    mov ecx, eax

    ; fat_entry_offset = fat_offset % bytes_per_sector
    movzx eax, word [bpb_info.bytes_per_sector]
    xor dx, dx
    div ebx
    mov bx, dx

    mov di, 0x1000
    mov es, di
    xor di, di

    mov word [DAP+2], 0x01 ; loading 1 sector at a time
    mov word [DAP+4], di
    mov word [DAP+6], es
    mov word [DAP+8], cx
    mov word [DAP+10], 0x0000
    mov dword [DAP+12], 0x00000000
    
    push bx
    mov bx, load_fat_error
    call extended_read
    pop bx

    ; cluster = (4 bytes)(es:di + fat_entry_offset) & 0x0FFFFFFF;
    mov ax, di
    add bx, ax
    mov eax, dword [es:bx]
    and eax, 0x0FFFFFFF
    mov [cluster], eax

    popad
    ret

.read_memory:
    mov word [DAP+2], 0x01 ; loading 1 sector at a time
    mov word [DAP+4], di
    mov word [DAP+6], es
    mov word [DAP+8], bx
    mov word [DAP+10], 0x0000
    mov dword [DAP+12], 0x00000000

    mov bx, load_fat_error
    call extended_read
    ret