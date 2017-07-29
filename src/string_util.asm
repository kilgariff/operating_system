; cx should contain the number of characters
; to test for equality before stopping.

memcmp:

	clc ; clear carry flag
	cld ; clear direction flag (cmpsb auto-increments)
	xor bx, bx ; use bx as a counter

	.loop:

		cmp bx, cx
		jne .not_finished_yet

		stc
		ret

		.not_finished_yet:

		cmpsb
		jz .equal

		clc
		ret

		.equal:

		add bx, 1

		jmp .loop

strcmp:

	clc ; clear carry flag
	cld ; clear direction flag (cmpsb auto-increments)

	.loop:
		
		cmpsb	
		jz .equal

		clc
		ret

		.equal:
		mov al, [si]
		cmp al, 0
		jne .loop ; not finished yet

		stc
		ret
    
get_string:
	
	xor cl, cl		;clear cl to 0 for use as a counter
	.loop:
		mov ah, 0
		int 0x16		;wait for keypress
		
		cmp al, 0x08	;backspace pressed?
		je .backspace
		
		cmp al, 0x0D	;enter pressed?
		je .finished_get_string
		
		cmp cl, 0x3F	;chars input total 63?
		je .loop		;only allow backspace and enter
		
		mov ah, 0x0E
		int 0x10		;print character
		
		stosb			;put character in buffer
		inc cl
		jmp .loop
		
	.backspace:
		
		cmp cl, 0		;beginning of string?
		je .loop		;if so, go back to loop (no backspace performed)
		
		dec di
		mov byte [di], 0	;delete character
		dec cl
		
		mov ah, 0x0E
		mov al, 0x08
		int 10h			;move insertion point left
		
		mov al, ' '
		int 10h			;blank out character
		
		mov al, 0x08
		int 10h			;move insertion point left again
		
		jmp .loop
		
	.finished_get_string:

		mov al, 0	;null terminator
		stosb
		
		mov ah, 0x0E
		mov al, 0x0D
		int 0x10
		
		mov al, 0x0A
		int 0x10		;newline
		
		ret
	
int16_to_str:

	; Max value that an int16 can represent is 65535,
	; which has 5 characters max. To isolate each character,
	; we need to keep dividing by 10, converting the remainder
	; into ASCII and using the quotient as the numerator in the
	; next pass.

	; Numerator (high and low)
	mov ax, si

	; Denominator
	mov cx, 10

	mov bx, di
	add di, 6
	mov byte [di], 0

	.loop:

		dec di

		xor dx, dx
		div cx
		add dx, '0' ; Add ascii '0' to convert dx's value into ascii.

		mov byte [di], dl

		cmp di, bx
		jne .loop

	.trim:

		cmp byte [di], '0'
		jne .done
		cmp byte [di + 1], 0
		je .done
		inc di
		jmp .trim

	.done:
		ret

; int16_to_str test buffer
test_buffer times 6 db 0

test_int16_to_str:

	call clear_registers
	mov si, 1337
	mov di, test_buffer
	call int16_to_str
	mov si, di
	call print_string
	ret