[ORG 0x7C00]
cli

;
; Bootloader Stage 1
;

jmp stage_1

%include "string_util.asm"
%include "lba.asm"

stage_1:

	;
	; Change active display page to 1
	;

	mov ah, 0x05
	mov al, 0
	int 0x10

	;
	; Read Stage 2 into memory using LBA.
	;

	call setup_lba
	call load_stage_2
	jmp stage_2

times 510-($-$$) db 0

; mark end of stage 1 sector as bootable
db 0x55
db 0xAA

stage_2_load_point:

;
; Bootloader Stage 2
;

%include "cpuid.asm"
%include "vesa.asm"
%include "simple_prompt.asm"
%include "long_mode.asm"

;
; Stage 2 (initialise display)
;

stage_2:

	; We're not in long mode yet, so we can run the command prompt

	; call begin_command_prompt

	call setup_cpu_info
	call cpu_require_long_mode
	call vesa_setup_display

	call vesa_show_modes

	mov cx, 323
	call vesa_print_mode_info

	mov ax, 323
	call vesa_switch_mode

	call enter_long_mode

	hlt

[BITS 64]

%include "interrupts.asm"

stack64_top: dq 16
stack64_bottom:

; Long-mode entry point.
main64:

	;
	; Set up the stack
	;

	mov rsp, stack64_bottom
	mov rbp, stack64_bottom

	.test_stack_part_1:

		mov rax, 0xF00DF00DF00DF00D
		push rax
		cmp rax, qword [stack64_bottom - 8]
		je .test_stack_part_2
		hlt

	.test_stack_part_2:

		mov rbx, 0xBAADD00DBAADD00D
		push rbx
		cmp rbx, qword [stack64_bottom - 16]
		je .stack_works
		hlt

	.stack_works:

		pop rbx
		pop rax

	;
	; Set up interrupts
	;

	lidt [IDT64.Pointer]

	;
	; Initialize PS/2 mouse.
	;

	;
	; Main Loop:
	;

	mov esi, 0

	.main_loop:

		mov ecx, 600
		mov edi, 0x00200000 ; Physical address is 0xE0000000, memory mapped address is 0x00200000 (2 MiB in)

		;
		; PS2 mouse input.
		; (this is very rough and ad-hoc just now)
		; http://wiki.osdev.org/Mouse_Input#Initializing_a_PS2_Mouse
		;

		xor al, al
		in al, 0x64

		; Keyboard controller status register:
		; https://www.win.tue.nl/~aeb/linux/kbd/scancodes-11.html
		test al, 0b100001

		; Skip mouse read if there's no mouse data.
		jz .no_mouse_data

			xor eax, eax

			; Read 3 bytes from the mouse/keyboard port (byte 1 is state, 2 and 3 are coords)
			in al, 0x60
			shl al, 8
			
			in al, 0x60
			shl al, 8

			in al, 0x60
			shl al, 8

			; Mouse data received; set esi to mouse y coord
			or eax, 0xFF
			mov esi, eax

		.no_mouse_data:

		.draw_row:

			mov ebx, ecx
			mov ecx, 800

			; Render a flat-colour row of pixels.

			mov edx, ebx
			add edx, esi
			and edx, 0xFF

			xor eax, eax
			or eax, 0xFF ; Alpha
			shl eax, 8
			or eax, edx  ; Blue
			shl eax, 8
			or eax, edx  ; Green
			shl eax, 8
			or eax, edx  ; Red

			rep stosd
			mov ecx, ebx
			loop .draw_row

		add esi, 1

		jmp .main_loop

		hlt
[BITS 16]

times 4096-($-$$) db 0