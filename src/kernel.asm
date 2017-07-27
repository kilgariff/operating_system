mov ax, 0x07C0
mov ds, ax
mov es, ax

; select active display page
; page x) ah: 0x05 al: x

mov ah, 0x05
mov al, 1
int 0x10

jmp stage1_begin

; include external routines

%include "BIOS_routines.asm"
%include "string_util.asm"

; define static debug message data

msg_lba_not_supported: db 'Error: LBA support is unavailable', 0x0D, 0x0A, 0
msg_lba_supported: db 'LBA support is available', 0x0D, 0x0A, 0
msg_lba_read_success: db 'LBA read succeeded', 0x0D, 0x0A, 0
msg_lba_read_failed: db 'Error: LBA read failed', 0x0D, 0x0A, 0

; define disk access packet to describe disk reads and writes
; (initial setup to read stage2)

disk_access_packet:
	db	0x10
	db	0
	.num_blocks:
		; BIOS interrupt 0x13 changes this to the number of blocks actually
		; read or written. I think each block is 512 bytes (same as one sector).
		dw	9 ; 10 in total, including this one.
	.destination_buffer:
		; these parameters are a SEGMENT:OFFSET address pair, but are stored
		; in reverse order due to processor being little-endian.
		dw	STAGE2_LOAD_ADDR
		dw	0x07C0
	.lba:
		dd	1		; read mode
		dd	0

; define stage1 routines

clear_registers:
	xor ax, ax
	xor bx, bx
	xor cx, cx
	xor dx, dx
	xor di, di
	ret

stage1_begin:

	.check_lba_supported:
		mov ah, 0x41
		mov bx, 0x55AA
		mov dl, 0x80

	call clear_registers
	jnc .lba_supported

	.lba_not_supported:

		mov si, msg_lba_not_supported
		call print_string
		hlt

	.lba_supported:

		mov si, msg_lba_supported
		call print_string

	mov si, disk_access_packet
	mov ah, 0x42
	mov al, 0x0
	mov dl, 0x80 ; drive number 0 (OR the drive # with 0x80)
	int 0x13

	call clear_registers
	jnc .lba_read_success

	.lba_read_failed:

		mov si, msg_lba_read_failed
		call print_string
		hlt

	.lba_read_success:

		mov si, msg_lba_read_success
		call print_string

		jmp stage2_begin

times 510-($-$$) db 0

; mark end of stage 1 sector as bootable
db 0x55
db 0xAA

STAGE2_LOAD_ADDR:

%include "vesa.asm"

jmp stage2_begin

; define static message data
msg_newline db 0x0D, 0x0A, 0
msg_ready db 0x0D, 0x0A, 'Ready', 0x0D, 0x0A, 0
msg_prompt db '> ', 0
msg_help db 'Valid commands: ', 0x0D, 0x0A, 0
msg_invalid_command db 'Invalid input', 0x0D, 0x0A, 0

; define input buffer for receiving commands
input_buffer times 64 db 0

; define command strings
cmd_help db 'help', 0
cmd_echo db 'echo', 0
cmd_echo_len equ $ - cmd_echo

;
; Stage 2 (initialise display)
;

stage2_begin:

;call test_int16_to_str
call vesa_setup_display

call clear_registers
mov si, msg_ready		;put a pointer to the welcome message in si
call print_string

mainloop:

	xor di, di

	mov si, msg_prompt	;put a pointer to the prompt string in si
	call print_string
	
	mov di, input_buffer	;put a pointer to the input buffer in di
	call get_string
	
	mov si, input_buffer
	cmp byte [si], 0	;blank line?
	je mainloop			;yes, ignore it
		
	mov si, input_buffer
	mov di, cmd_help
	call strcmp
	jc help
	
	mov si, input_buffer
	mov di, cmd_echo
	mov cx, cmd_echo_len - 1
	call memcmp
	jc echo ; at this point, memcmp will have left si in the correct location to echo

	mov si, msg_invalid_command
	call print_string
	
	jmp mainloop

help:

	mov si, msg_help
	call print_string

	mov si, msg_newline
	call print_string
	
	jmp mainloop

echo:

	call print_string

	mov si, msg_newline
	call print_string
	
	jmp mainloop

times 5120-($-$$) db 0
