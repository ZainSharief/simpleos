; src/bootloader/include/lba_to_chs.asm

; expects lba in si -> returns ch = cylinder, dh = head, cl = sector
; MAKE SURE TO SAVE REGISTERS BEFORE CALLING
lba_to_chs:

    ; cylinder = LBA / (heads * sectors_per_track)
    mov ax, [head_count]
    mul word [sectors_per_track]
    mov cx, ax
    mov ax, si
    xor dx, dx
    div cx
    mov ch, al ; cylinder

    mov bx, dx ; temp

    ; head = temp / sectors_per_track
    mov ax, bx
    xor dx, dx
    div word [sectors_per_track]
    push ax

    ; sector = (temp % sectors_per_track) + 1
    mov ax, dx
    add ax, 0x01
    mov cl, al ; sector
    pop ax

    mov dh, al ; head
    ret