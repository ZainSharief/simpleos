; src/bootloader/include/load_fat.asm

; inputs: none
; outputs: fat table loaded at 0x1000:0x0000
; requires:
; -  print/print_num 
; -  load_fat_error/end_string strings
; -  bytes_per_sector, reserved_sectors, sectors_per_fat_32
load_fat:

    pusha
    
    mov di, 0x1000
    mov es, di
    xor di, di
    
    ; maximum number of sectors can load at a time
    mov eax, 0x10000
    movzx ebx, word [bpb_info.bytes_per_sector]
    div ebx

    mov bx, word [bpb_info.reserved_sectors]
    mov ecx, dword [bpb_info.sectors_per_fat_32]

    call .iterate_fat
    popa
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
    mov dl, [bpb_info.drive_number]
    int 0x13

    mov dx, ax
    pop ax
    jc .load_fat_error
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

.load_fat_error:
    mov si, load_fat_error
    call print
    push ax
    shr dx, 8
    mov ax, dx
    call print_num
    pop ax
    mov si, end_string
    call print

    popa
    jmp load_fat