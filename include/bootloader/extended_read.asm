; include/bootloader/extended_read.asm

; inputs: filled DAP, drive_number, bx = error message
; outputs: data at address specified in DAP
;
extended_read:
    ; extended read sectors from drive
    push si
    push ax
    push dx

.read:
    mov si, DAP
    mov ah, 0x42
    mov dl, [bpb_info.drive_number]
    int 0x13
    jc .read_error

    pop dx 
    pop ax 
    pop si
    ret

.read_error:
    ; print error message + retry
    mov si, bx
    call print
    shr ax, 8
    call print_num
    mov si, end_string
    call print
    jmp .read