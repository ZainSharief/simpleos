; src/kernel/kernel.asm
bits 16             ; real mode    
org 0x1000          ; load address

start:
    jmp $           ; loop forever
