; include/bootloader/load_fat.asm

; inputs: es:di
; outputs: fat table loaded at 0x1000:0x0000
; requires:
; -  print/print_num 
; -  load_fat_error/end_string strings
; -  bytes_per_sector, reserved_sectors, sectors_per_fat_32
load_fat:
    pushad

    ; maximum number of sectors can load at a time
    mov eax, 0x10000
    movzx ebx, word [bpb_info.bytes_per_sector]
    div ebx

    mov bx, word [bpb_info.reserved_sectors]
    mov ecx, dword [bpb_info.sectors_per_fat_32]

    call .iterate_fat
    popad
    ret

.read_memory:
    mov word [DAP+2], ax
    mov word [DAP+4], di
    mov word [DAP+6], es
    mov word [DAP+8], bx
    mov word [DAP+10], 0x0000
    mov dword [DAP+12], 0x00000000

    push bx
    mov bx, load_fat_error
    call extended_read
    pop bx
    ret

.iterate_fat:
    call .read_memory

    push ax
    mov ax, es 
    add ax, 0x1000
    mov es, ax
    pop ax
    add bx, ax

    sub cx, ax
    cmp cx, ax
    jle .last_iteration
    jmp .iterate_fat

.last_iteration:
    mov ax, cx
    call .read_memory
    ret