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