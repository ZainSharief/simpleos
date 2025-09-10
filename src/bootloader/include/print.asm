; src/bootloader/include/print.asm

; inputs: si (pointer to first letter)
; outputs: BIOS print 
; Note: input MUST have an ending 0 character
print:
    pusha

.print_loop:
    lodsb             ; byte from SI -> AL, increment SI
    cmp al, 0x00      ; check if end of string
    je .end_print
    mov ah, 0x0E      ; tells to print character in AL
    int 0x10          ; print interrupt
    jmp .print_loop
    
.end_print:
    popa
    ret  