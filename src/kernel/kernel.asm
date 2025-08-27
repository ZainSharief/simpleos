bits 16
org 0x10000

start:
    jmp main

; prints string at SI
print:
    push ax

.print_loop:
    lodsb             ; byte from SI -> AL, increment SI
    cmp al, 0         ; check if end of string
    je .end_print
    mov ah, 0x0E      ; tells to print character in AL
    int 0x10          ; print interrupt
    jmp .print_loop
    
.end_print:
    pop ax
    ret               

main:
    mov ax, 0x1000
	mov ds, ax
	mov es, ax

    mov ax, 0x9000 
    mov ss, ax
    mov sp, 0xFFFF 

    mov si, msg
    call print

    jmp $               ; loop forever

msg db 'Kernel Loaded!', 0
