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
		dw	2
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

jmp stage2_begin

; define static message data
msg_newline db 0x0D, 0x0A, 0
msg_ready db 0x0D, 0x0A, 'Ready', 0x0D, 0x0A, 0
msg_prompt db '> ', 0
msg_help db 'Valid commands: ', 0x0D, 0x0A, 0
msg_invalid_command db 'Invalid input', 0x0D, 0x0A, 0
msg_vbe_available db 'VBE 2 available', 0x0D, 0x0A, 0
msg_vbe_unavailable db 'VBE 2 unavailable', 0x0D, 0x0A, 0
msg_vbe_get_info_success db 'Successfully retrieved VBE info', 0x0D, 0x0A, 0
msg_vbe_cannot_get_info db 'Error: Something went wrong when trying to get VBE info', 0x0D, 0x0A, 0

; define input buffer for receiving commands
input_buffer resb 64

; define command strings
cmd_help db 'help', 0
cmd_echo db 'echo', 0
cmd_echo_len equ $ - cmd_echo

;
; VBE info structure
;

vbe_info_block:

	vbe_signature resb 4
	vbe_version resw 1
	vbe_oem_string_ptr_offset resw 1
	vbe_oem_string_ptr_base resw 1
	vbe_capabilities resb 4
	vbe_video_mode_ptr resw 2
	vbe_total_memory resw 1

	; VBE 2.0
	vbe_oem_software_rev resw 1
	vbe_oem_vendor_string_ptr resw 2
	vbe_oem_product_name_ptr resw 2
	vbe_oem_product_rev_ptr resw 2
	vbe_reserved resb 222
	vbe_oem_data resb 256

vbe_info_block_size equ $ - vbe_info_block

;
; VBE video mode structure
;

vbe_mode_block:

	; VESA 1.0
	vbe_mode_attributes resw 1
	vbe_mode_window_attributes_a resb 1
	vbe_mode_window_attributes_a resb 2
	vbe_mode_window_granularity resw 1
	vbe_mode_window_size resw q
	vbe_mode_window_start_segment_a resw 1
	vbe_mode_window_start_segment_b resw 1
	vbe_mode_window_far_position_func resw 2
	vbe_mode_bytes_per_scan_line resw 1

	; VESA OEM (optional in v1.0/1.1)
	vbe_mode_width resw 1
	vbe_mode_height resw 1
	vbe_mode_character_width resb 1
	vbe_mode_character_height resb 1
	vbe_mode_memory_planes resb 1
	vbe_mode_bit_depth resb 1
	vbe_mode_banks resb 1
	vbe_mode_memory_model_type resb 1
	vbe_mode_bank_size resb 1
	vbe_mode_image_page_capacity resb 1
	vbe_mode_reserved_1 resb 1

	; VBE 1.2+
	vbe_mode_red_mask_size resb 1
	vbe_mode_red_field_position resb 1
	vbe_mode_green_mask_size resb 1
	vbe_mode_green_field_position resb 1
	vbe_mode_blue_mask_size resb 1
	vbe_mode_blue_field_position resb 1
	vbe_mode_reserved_mask_size resb 1
	vbe_mode_reserved_field_position resb 1
	vbe_mode_direct_color_mode_info resb 1

	; VBE 2.0+
	vbe_mode_video_buffer_address resw 2
	vbe_mode_offscreen_memory_pointer resw 2
	vbe_mode_offscreen_memory_size resw 1

	; VBE 3.0
	; TODO: Fill in VBE 3.0 structure
	; 32h	WORD	bytes per scan line in linear modes
	; 34h	BYTE	number of images (less one) for banked video modes
	; 35h	BYTE	number of images (less one) for linear video modes
	; 36h	BYTE	linear modes: size of direct color red mask (in bits)
	; 37h	BYTE	linear modes: bit position of red mask LSB (e.g. shift count)
	; 38h	BYTE	linear modes: size of direct color green mask (in bits)
	; 39h	BYTE	linear modes: bit position of green mask LSB (e.g. shift count)
	; 3Ah	BYTE	linear modes: size of direct color blue mask (in bits)
	; 3Bh	BYTE	linear modes: bit position of blue mask LSB (e.g. shift count)
	; 3Ch	BYTE	linear modes: size of direct color reserved mask (in bits)
	; 3Dh	BYTE	linear modes: bit position of reserved mask LSB
	; 3Eh	DWORD	maximum pixel clock for graphics video mode, in Hz
	; 42h 190 BYTEs	reserved (0)

vbe_mode_block_size equ $ - vbe_mode_block

;
; Stage 2 (initialise display)
;

stage2_begin:

setup_display:

	; Check whether VBE 2 is available.

	call clear_registers
	mov dword [vbe_signature], 'VBE2'
	mov ax, 0x4F00
	mov di, vbe_info_block
	int 0x10
	cmp ax, 0x004F
	je .fine

	call clear_registers
	mov si, msg_vbe_unavailable
	call print_string
	hlt

	.fine:

		call clear_registers
		mov si, msg_vbe_available
		call print_string

	call clear_registers
	mov si, vbe_signature
	call print_string

	; Get VBE video mode info.

	call clear_registers
	mov ax, 0x4F01
	mov di, vbe_info_block
	mov cx, 0x4101
	and cx, 0xfff
	int 0x10

	cmp dword [vbe_signature], 'VESA'
	je .get_info_fine

	call clear_registers
	mov si, msg_vbe_cannot_get_info
	call print_string

	hlt

	.get_info_fine:

	call clear_registers
	mov si, msg_vbe_get_info_success
	call print_string

	;push bp
	;push ds
	;push ax
	;mov ax, vbe_oem_string_ptr_base
	;mov ds, ax
	;mov bp, vbe_oem_string_ptr_offset
	;mov si, [ds:bp]
	;pop ax
	;pop ds
	;pop bp

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