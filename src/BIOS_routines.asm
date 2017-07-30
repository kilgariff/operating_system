; Routine to print a string using BIOS interrupt 0x10
; clobbers ax and si

print_string:

    xor ax, ax

    lodsb
    or al, al
    jz .done
    
    mov ah, 0xE
    int 0x10
    jmp print_string

    .done:
        ret