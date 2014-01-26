; Specify base segment address to 0x7c00,
; as the BIOS starts executing code from address 0x07c0
[ORG 0x7c00]

xor ax, ax
mov ds, ax

; Disable interrupts and begin program
cli
jmp main

; Routine declarations
%include "BIOS_routines.asm"
%include "character_display_routines.asm"

main:
    mov dh, 0
    mov dl, 0
    
    mov ax, 0xb800
    mov es, ax
    
    mov ax, 0
    loop_start:
        mov si, vidmem_message
        
        push ax
        call VIDMEM_print_string
        pop ax
        
        add ax, 1
        cmp ax, 20
        jne loop_start
    
    jmp $
  
; Constant definitions
bios_message db "This string is output using BIOS interrupts.", 0
vidmem_message db "This string is output using direct access to video memory", 0

; The last two bytes tell the BIOS that this 512 byte sector is bootable
times 510-($-$$) db 0
dw 0xAA55