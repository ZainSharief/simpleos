; include/bootloader/load_root.asm

; inputs: es:di (where to load root), root_cluster
; outputs: 
load_root: 
    pusha
    mov eax, [bpb_info.root_cluster]
    mov [cluster], eax
    call cluster_to_lba
    mov ax, 0x01
    call .iterate_cluster
    popa
    ret
    
.iterate_cluster:

    call .read_memory

    push ds
    mov bx, 0x1000 ; fat address
    mov ds, bx

    mov ebx, [cluster]
    shl ebx, 2
    mov bx, [ds:bx]
    call cluster_to_lba
    mov ecx, dword [ds:bx]
    pop ds

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

    push bx
    mov bx, load_root_error
    call extended_read
    pop bx
    ret

; input: [cluster]
; outputs: bx = lba 
cluster_to_lba:

    push eax
    push ecx

    ; first_data_sector = reserved_sectors + (number_of_fats * sectors_per_fat_32)
    movzx eax, byte [bpb_info.number_of_fats]
    mov ebx, [bpb_info.sectors_per_fat_32]
    mul ebx 
    movzx ebx, word [bpb_info.reserved_sectors]
    add ebx, eax

    ; lba = first_data_sector + ((root_cluster - 2) * sectors_per_cluster)
    mov eax, [cluster]
    sub eax, 0x02
    movzx ecx, byte [bpb_info.sectors_per_cluster]
    mul ecx
    add ebx, eax

    pop ecx
    pop eax
    ret