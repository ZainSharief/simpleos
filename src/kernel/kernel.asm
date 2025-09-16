bits 32
org 0x100000

pm_kernel_start:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x0009F000

    mov edi, 0xB8000
    mov esi, kernel_msg

.print_loop32:
    lodsb
    cmp al, 0
    je .done
    mov ah, 0x07
    stosw
    jmp .print_loop32

.done:
    hlt
    jmp .done

kernel_msg db "Kernel Loaded!", 0
