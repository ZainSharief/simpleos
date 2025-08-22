; src/bootloader/boot.asm
bits 16               ; real mode
org 0x7C00            ; load address for BIOS

%define ENDSTRING 0x00

start:
    call .main

; prints string at SI
.print:
    lodsb             ; byte from SI -> AL, increment SI
    cmp al, 0         ; check if end of string
    je .end_print
    mov ah, 0x0E      ; tells to print character in AL
    int 0x10          ; print interrupt
    jmp .print
.end_print:
    ret               ; loop forever

.main: 
    mov si, msg       ; load pointer to message
    call .print

msg db "Hello World!", ENDSTRING

times 510-($-$$) db 0
dw 0xAA55               ; gotta end with this magic number
