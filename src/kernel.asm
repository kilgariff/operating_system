;
; Bootloader Stage 1
;

jmp stage_1

%include "BIOS_routines.asm"
%include "string_util.asm"
%include "lba.asm"

clear_registers:

	xor ax, ax
	xor bx, bx
	xor cx, cx
	xor dx, dx
	xor di, di
	ret

stage_1:

	;
	; Set up data segment and extra segment registers
	; to use 0x07C0 as a base, as this is the memory
	; location the bios will load our code into.
	;

	mov ax, 0x07C0
	mov ds, ax
	mov es, ax

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

%include "vesa.asm"

prompt_strings:

	.newline db 0x0D, 0x0A, 0
	.ready db 0x0D, 0x0A, 'Ready', 0x0D, 0x0A, 0
	.prompt db '> ', 0
	.help db 'Valid commands: help, echo', 0x0D, 0x0A, 0
	.invalid_command db 'Invalid input', 0x0D, 0x0A, 0
	.invalid_args db 'Invalid arguments to command', 0x0D, 0x0A, 0

input_buffer:

	.data times 64 db 0

command_strings:

	.help db 'help', 0
	.echo db 'echo', 0
	.echo_len equ $ - .echo
	.set_video_mode db 'vidmode set', 0
	.set_video_mode_len equ $ - .set_video_mode
	.show_video_modes db 'vidmode list', 0

;
; Stage 2 (initialise display)
;

stage_2:

	call vesa_setup_display

	;mov ax, 324
	;call vesa_switch_mode

	call clear_registers
	mov si, prompt_strings.ready		;put a pointer to the welcome message in si
	call print_string

	.mainloop:

		xor di, di

		mov si, prompt_strings.prompt	;put a pointer to the prompt string in si
		call print_string
		
		mov di, input_buffer	;put a pointer to the input buffer in di
		call get_string
		
		mov si, input_buffer
		cmp byte [si], 0	;blank line?
		je .mainloop			;yes, ignore it
			
		mov si, input_buffer
		mov di, command_strings.help
		call strcmp
		jc .help
		
		mov si, input_buffer
		mov di, command_strings.echo
		mov cx, command_strings.echo_len - 1
		call memcmp
		jc .echo ; at this point, memcmp will have left si in the correct location to echo

		mov si, input_buffer
		mov di, command_strings.set_video_mode
		mov cx, command_strings.set_video_mode_len - 1
		call memcmp
		jc .set_video_mode

		mov si, input_buffer
		mov di, command_strings.show_video_modes
		call strcmp
		jc .show_video_modes

		mov si, prompt_strings.invalid_command
		call print_string
		
		jmp .mainloop

	.help:

		mov si, prompt_strings.help
		call print_string

		mov si, prompt_strings.newline
		call print_string
		
		jmp .mainloop

	.echo:

		cmp byte [si], 0
		je .invalid_args

		inc si

		call print_string

		mov si, prompt_strings.newline
		call print_string
		
		jmp .mainloop

	.set_video_mode:

		cmp byte [si], 0
		je .invalid_args

		inc si

		; TODO: Populate ax with the input converted to a numerical value.
		; For now, force a specific mode.

		mov ax, 261
		call vesa_switch_mode

		mov si, prompt_strings.newline
		call print_string

		jmp .mainloop

	.show_video_modes:

		call vesa_show_modes
		jmp .mainloop

	.invalid_args:

		mov si, prompt_strings.invalid_args
		call print_string

		jmp .mainloop

	times 5120-($-$$) db 0
