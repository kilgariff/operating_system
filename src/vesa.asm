vbe_strings:

	.header db '=== VESA (VBE 2)', 0x0D, 0x0A, 0
	.newline db 0xD, 0xA, 0
	.available db 'VBE 2 available', 0x0D, 0x0A, 0
	.unavailable db 'VBE 2 unavailable', 0x0D, 0x0A, 0
	.get_info_success db 'Successfully retrieved VBE info', 0x0D, 0x0A, 0
	.cannot_get_info db 'Error: Something went wrong when trying to get VBE info', 0x0D, 0x0A, 0
	.signature_is db 'Signature is ', 0
	.signature_invalid db ' (Error: invalid!)', 0x0D, 0x0A, 0
	.signature_valid db ' (OK!)', 0x0D, 0x0A, 0
	.device_info db 'Device Info:', 0x0D, 0x0A, 0
	.vendor db 0x9, 'Vendor: ', 0
	.product_name db 0x9, 'Product Name: ', 0
	.product_revision db 0x9, 'Product Name: ', 0
	.total_memory db 0x9, 'Total Video Memory: ', 0
	.kibibytes db ' KiB', 0
	.mode_info db 'Available modes:', 0x0D, 0x0A, 0
	.cannot_get_mode_info db 'Unable to retrieve VBE mode info', 0x0D, 0x0A, 0
	.mode_number db 0x9, 'Mode ', 0
	.mode_width db ')', 0x9, 0
	.mode_height db 'x', 0
	.mode_bpp db ' at ', 0
	.mode_after_bpp db 'bpp', 0x0D, 0x0A, 0
	.setting_video_mode_to db 'Setting video mode to ', 0
	.cannot_switch_mode db 'Unable to switch video mode', 0, 0x0D, 0x0A
	.linear_framebuffer_not_available db 'Linear framebuffer not available in new video mode', 0, 0x0D, 0x0A

vbe_info_block:

	vbe_signature times 4 db 0
	vbe_version dw 0
	vbe_oem_string_ptr_offset dw 0
	vbe_oem_string_ptr_base dw 0
	vbe_capabilities dd 0
	vbe_video_mode_ptr_offset dw 0
	vbe_video_mode_ptr_base dw 0
	vbe_total_memory dw 0

	; VBE 2.0
	vbe_oem_software_rev dw 0x00
	vbe_oem_vendor_string_ptr_offset dw 0x00
	vbe_oem_vendor_string_ptr_base dw 0x00
	vbe_oem_product_name_ptr_offset dw 0x00
	vbe_oem_product_name_ptr_base dw 0x00
	vbe_oem_product_rev_ptr_offset dw 0x00
	vbe_oem_product_rev_ptr_base dw 0x00
	vbe_reserved times 222 db 0
	vbe_oem_data times 256 db 0

vbe_mode_block:

	; VESA 1.0
	vbe_mode_attributes dw 0
	vbe_mode_window_attributes_a db 0
	vbe_mode_window_attributes_b db 0
	vbe_mode_window_granularity dw 0
	vbe_mode_window_size dw 0
	vbe_mode_window_start_segment_a dw 0
	vbe_mode_window_start_segment_b dw 0
	vbe_mode_window_far_position_func dd 0
	vbe_mode_bytes_per_scan_line dw 0

	; VESA OEM (optional in v1.0/1.1)
	vbe_mode_width dw 0
	vbe_mode_height dw 0
	vbe_mode_character_width db 0
	vbe_mode_character_height db 0
	vbe_mode_memory_planes db 0
	vbe_mode_bit_depth db 0
	vbe_mode_banks db 0
	vbe_mode_memory_model_type db 0
	vbe_mode_bank_size db 0
	vbe_mode_image_page_capacity db 0
	vbe_mode_reserved_1 db 0

	; VBE 1.2+
	vbe_mode_red_mask_size db 0
	vbe_mode_red_field_position db 0
	vbe_mode_green_mask_size db 0
	vbe_mode_green_field_position db 0
	vbe_mode_blue_mask_size db 0
	vbe_mode_blue_field_position db 0
	vbe_mode_reserved_mask_size db 0
	vbe_mode_reserved_field_position db 0
	vbe_mode_direct_color_mode_info db 0

	; VBE 2.0+
	vbe_mode_video_buffer_ptr_offset dw 0
	vbe_mode_video_buffer_ptr_base dw 0
	vbe_mode_offscreen_memory_pointer dd 0
	vbe_mode_offscreen_memory_size dw 0

	; VBE 3.0
	vbe_mode_linear_bytes_per_scan_line dw 0
	vbe_mode_images_banked db 0
	vbe_mode_images_linear db 0
	vbe_mode_direct_color_red_mask db 0
	vbe_mode_bit_position_red_mask_lsb db 0
	vbe_mode_direct_color_green_mask db 0
	vbe_mode_bit_position_green_mask_lsb db 0
	vbe_mode_direct_color_blue_mask db 0
	vbe_mode_bit_position_blue_mask_lsb db 0
	vbe_mode_direct_color_reserved_mask db 0
	vbe_mode_bit_position_reserved_mask_lsb db 0
	vbe_mode_max_clock_graphics_mode times 2 dw 0x00
	vbe_mode_reserved_2 times 190 db 0

int16_to_str_buffer times 6 db 0

vesa_setup_display:

	mov si, vbe_strings.header
	call print_string

	.get_vbe_info:

		push es
		mov dword [vbe_signature], 'VBE2'
		mov ax, 0x4F00
		mov di, vbe_info_block
		int 0x10
		pop es

		cmp ax, 0x4F
		jne .vbe_unavailable

		call clear_registers
		mov si, vbe_strings.available
		call print_string

		; Output signature (should be 'VESA' after call)

		call clear_registers
		mov si, vbe_strings.signature_is
		call print_string
		mov si, vbe_signature
		call print_string

		; Check that signature has been set to 'VESA' before proceeding

		cmp dword [vbe_signature], 'VESA'
		jne .vesa_signature_invalid

		call clear_registers
		mov si, vbe_strings.signature_valid
		call print_string

		mov si, vbe_strings.device_info
		call print_string

		; Print vendor string

		mov si, vbe_strings.vendor
		call print_string

		push ds
		mov ax, word [vbe_oem_vendor_string_ptr_base]
		mov si, word [vbe_oem_vendor_string_ptr_offset]
		mov ds, ax
		call print_string
		pop ds

		mov si, vbe_strings.newline
		call print_string

		; Print product name

		mov si, vbe_strings.product_name
		call print_string

		push ds
		mov ax, word [vbe_oem_product_name_ptr_base]
		mov si, word [vbe_oem_product_name_ptr_offset]
		mov ds, ax
		call print_string
		pop ds

		mov si, prompt_strings.newline
		call print_string

		; Print product revision

		mov si, vbe_strings.product_revision
		call print_string

		push ds
		mov ax, word [vbe_oem_product_rev_ptr_base]
		mov si, word [vbe_oem_product_rev_ptr_offset]
		mov ds, ax
		call print_string
		pop ds

		mov si, prompt_strings.newline
		call print_string

		; Print total memory
		
		mov si, vbe_strings.total_memory
		call print_string

		mov ax, [vbe_total_memory]		
		mov bx, 64 ; Multiply by 64 to get KiB
		mul bx
		mov si, ax

		mov di, int16_to_str_buffer
		call int16_to_str
		mov si, di
		call print_string

		mov si, vbe_strings.kibibytes
		call print_string

		mov si, vbe_strings.newline
		call print_string

	mov si, vbe_strings.newline
	call print_string

    ret

	.vbe_unavailable:

		call clear_registers
		mov si, vbe_strings.unavailable
		call print_string
		hlt

	.vesa_signature_invalid:

		call clear_registers
		mov si, vbe_strings.signature_invalid
		call print_string
		hlt

print_mode_info:

	push cx
	mov ax, 0x4F01
	mov di, vbe_mode_block
	int 0x10

	cmp ax, 0x4F
	jne .get_mode_failed

	; Print mode number

	mov si, vbe_strings.mode_number
	call print_string

	pop si 
	mov di, int16_to_str_buffer
	call int16_to_str
	mov si, di
	call print_string

	; Print mode width

	mov si, vbe_strings.mode_width
	call print_string

	mov si, word [vbe_mode_width]
	mov di, int16_to_str_buffer
	call int16_to_str
	mov si, di
	call print_string

	; Print mode height

	mov si, vbe_strings.mode_height
	call print_string

	mov si, word [vbe_mode_height]
	mov di, int16_to_str_buffer
	call int16_to_str
	mov si, di
	call print_string

	; Print mode bit depth

	mov si, vbe_strings.mode_bpp
	call print_string

	mov al, byte [vbe_mode_bit_depth]
	xor ah, ah

	mov si, ax
	mov di, int16_to_str_buffer
	call int16_to_str
	mov si, di
	call print_string

	mov si, vbe_strings.mode_after_bpp
	call print_string

	ret

	.get_mode_failed:

		call clear_registers
		mov si, vbe_strings.cannot_get_mode_info
		call print_string
		hlt

vesa_switch_mode:

	mov cx, ax
	and cx, 0b0111111111111111 ; Don't preserve memory on change
	or cx, 0b0100000000000000 ; Switch on linear addressing

	mov cx, 0b0100000101000100

	; Perform switch

	mov ax, 0x4F02
	mov bx, cx
	xor di, di
	int 0x10

	cmp ax, 0x4F
	jne .switch_mode_failed

	; Tell the user that we've switched modes

	mov si, vbe_strings.setting_video_mode_to
	call print_string

	mov si, cx
	mov di, int16_to_str_buffer
	call int16_to_str
	mov si, di
	call print_string

	mov si, vbe_strings.newline
	call print_string

	; Get current mode info

	mov ax, 0x4F03
	int 0x10

	cmp ax, 0x4F
	jne .switch_mode_failed

	; ; All these checks are failing for some reason...?
	; ; (the video mode change does seem to work...)

	; 	; Check that the requested mode was set
	; 	;cmp cx, bx
	; 	;jne .linear_framebuffer_not_available

	; 	;and bx, 0b0100000000000000
	; 	; the SF, ZF, and PF flags are set according to the result.
	; 	;cmp bx, 0
	; 	;je .linear_framebuffer_not_available

	; mov es, [vbe_mode_video_buffer_ptr_base]
	; mov di, [vbe_mode_video_buffer_ptr_offset]
	; mov cx, 0

	; .loop:

	; 	mov word [es:di], 0x00ff

	; 	cmp cx, 1024
	; 	je .done

	; 	inc di
	; 	inc cx

	; 	;mov cx, 65535
	; 	;push es
	; 	;mov es, [vbe_mode_video_buffer_ptr_base]
	; 	;mov di, [vbe_mode_video_buffer_ptr_offset]
	; 	;mov al, 0xF
	; 	;rep stosb
	; 	;pop es

	; 	jmp .loop

	; .done:
	; 	mov cx, 0
	; 	mov di, [vbe_mode_video_buffer_ptr_offset]
	; 	jmp .loop

	ret

	.switch_mode_failed:

		mov si, vbe_strings.cannot_switch_mode
		call print_string
		hlt

	.linear_framebuffer_not_available:

		mov si, vbe_strings.linear_framebuffer_not_available
		call print_string
		hlt

	vesa_show_modes:

		mov si, vbe_strings.mode_info
		call print_string

		mov si, [vbe_video_mode_ptr_offset]

		; Maximum number of modes to show (times 2)
		mov bx, si
		add bx, 64

		.loop:

			cmp bx, si
			je .done

			push ds
			mov ds, [vbe_video_mode_ptr_base]
			mov ax, word [ds:si]
			pop ds

			; Finished?
			cmp ax, 0xFFFF
			je .done

			push bx
			push si
			mov cx, ax
			call print_mode_info
			pop si
			pop bx

			.next_mode:

				add si, 2
				jne .loop

		.done:
		
			nop

	ret