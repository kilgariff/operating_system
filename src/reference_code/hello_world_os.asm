mov ax, 0x07C0		;put starting address in ax
mov ds, ax			;also put it in ds
mov es, ax			;and es

mov si, welcome
call print_string

print_string:

    lodsb
    or al, al
    jz .done
    
    mov ah, 0x0E
    int 0x10
    
    jmp print_string

.done:
    ret

welcome db 'Welcome to my OS', 0x0D, 0x0A, 0
	
times 510-($-$$) db 0
db 0x55
db 0xAA