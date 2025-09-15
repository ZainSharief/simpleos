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

; inputs: ax (number to be printed)
; outputs: BIOS print 
; Note: no space/ending character
print_num: 
    pusha 
    mov cx, 0 ; digit count 
    mov bx, 10 

    ; divisor for decimal 
    cmp ax, 0 
    jne .convert_loop 
    
    ; if number is 0, just print '0' 
    mov al, '0' 
    mov ah, 0x0E 
    int 0x10 
    jmp .done 
    
.convert_loop: 
    xor dx, dx ; clear dx for DIV 
    div bx ; AX / 10 
    push dx ; save remainder 
    inc cx 
    cmp ax, 0 
    jne .convert_loop 
    
.print_digits: 
    pop dx 
    add dl, '0' ; convert 0-9 -> ascii 
    mov ah, 0x0E 
    mov al, dl 
    int 0x10 
    loop .print_digits 
    
.done: 
    popa 
    ret