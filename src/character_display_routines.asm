xpos dw 0
ypos dw 0

VIDMEM_print_string:

    lodsb
    or al, al
    jz VIDMEM_carriage_return
    call VIDMEM_print_char
    jmp VIDMEM_print_string
    
VIDMEM_carriage_return:

    add word [ypos], 1
    mov word [xpos], 0
    ret
    
VIDMEM_print_char:
    
    ; al contains character
    ; ah is made to contain color data
    ; ax is retained so the register can be used
    mov ah, 0x0F
    push ax
    
    ; ax and bx are made to contain offsets
    mov ax, [ypos]
    mov dx, 160
    mul dx
    
    mov bx, [xpos]
    shl bx, 1
    
    ; di is made to contain memory offset
    mov di, 0
    add di, ax
    add di, bx
    
    ; character write is performed
    pop ax
    stosw
    
    ; advance to the right, ready for next character
    add byte [xpos], 1
    
    ret