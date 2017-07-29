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

print_wide_string:

    xor ax, ax

    lodsw
    or al, al
    jz .done
    
    mov ah, 0x0E
    int 0x10
    jmp print_wide_string
    
    .done:
        ret