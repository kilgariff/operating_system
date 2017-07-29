vbe_strings:

	.newline db 0xD, 0xA, 0
	.available db 'VBE 2 available', 0x0D, 0x0A, 0
	.unavailable db 'VBE 2 unavailable', 0x0D, 0x0A, 0
	.signature_is db 'VBE signature is: ', 0
	.signature_invalid db '(Error: VBE signature invalid!)', 0x0D, 0x0A, 0
	.signature_valid db '(OK!)', 0x0D, 0x0A, 0
	.get_info_success db 'Successfully retrieved VBE info', 0x0D, 0x0A, 0
	.cannot_get_info db 'Error: Something went wrong when trying to get VBE info', 0x0D, 0x0A, 0

;
; VBE info structure
;

align 16
vbe_info_block:

	vbe_signature times 4 db 0
	vbe_version dw 0
	vbe_oem_string_ptr_offset dw 0
	vbe_oem_string_ptr_base dw 0
	vbe_capabilities times 2 dw 0
	vbe_video_mode_ptr times 2 dw 0
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

vbe_info_block_size equ $ - vbe_info_block

;
; VBE video mode structure
;

vbe_mode_block:

	; VESA 1.0
	vbe_mode_attributes times 1 dw 0x00
	vbe_mode_window_attributes_a times 2 db 0
	vbe_mode_window_attributes_b times 2 db 0
	vbe_mode_window_granularity times 1 dw 0x00
	vbe_mode_window_size times 1 dw 0x00
	vbe_mode_window_start_segment_a times 1 dw 0x00
	vbe_mode_window_start_segment_b times 1 dw 0x00
	vbe_mode_window_far_position_func times 2 dw 0x00
	vbe_mode_bytes_per_scan_line times 1 dw 0x00

	; VESA OEM (optional in v1.0/1.1)
	vbe_mode_width times 1 dw 0x00
	vbe_mode_height times 1 dw 0x00
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
	vbe_mode_video_buffer_address times 2 dw 0x00
	vbe_mode_offscreen_memory_pointer times 2 dw 0x00
	vbe_mode_offscreen_memory_size times 1 dw 0x00

	; VBE 3.0
	vbe_mode_linear_bytes_per_scan_line times 1 dw 0x00
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

vbe_mode_block_size equ $ - vbe_mode_block

int16_to_str_buffer times 6 db 0

vesa_setup_display:

	; Check whether VBE 2 is available.

	push es
	mov dword [vbe_signature], 'VBE2'
	mov ax, 0x4F00
	mov di, vbe_info_block
	int 0x10
	pop es

	cmp ax, 0x4F
	je .vbe_available

	.vbe_unavailable:

		call clear_registers
		mov si, vbe_strings.unavailable
		call print_string
		hlt

	.vbe_available:

		call clear_registers
		mov si, vbe_strings.available
		call print_string

	; Output signature (should be 'VESA' after call)

	call clear_registers
	mov si, vbe_strings.signature_is
	call print_string
	mov si, vbe_signature
	call print_string
	mov si, prompt_strings.newline
	call print_string

	; Check that signature has been set to 'VESA' before proceeding

	cmp dword [vbe_signature], 'VESA'
	je .vesa_signature_valid

	.vesa_signature_invalid:

		call clear_registers
		mov si, vbe_strings.signature_invalid
		call print_string
		hlt

	.vesa_signature_valid:

		call clear_registers
		mov si, vbe_strings.signature_valid
		call print_string

	; Output info


	.vesa_print_vendor_string:

		push ds
		mov ax, word [vbe_oem_vendor_string_ptr_base]
		mov si, word [vbe_oem_vendor_string_ptr_offset]
		mov ds, ax
		call print_string
		pop ds

		mov si, vbe_strings.newline
		call print_string

	.vesa_print_product_name:

		push ds
		mov ax, word [vbe_oem_product_name_ptr_base]
		mov si, word [vbe_oem_product_name_ptr_offset]
		mov ds, ax
		call print_string
		pop ds

		mov si, prompt_strings.newline
		call print_string

	.vesa_print_product_rev:

		push ds
		mov ax, word [vbe_oem_product_rev_ptr_base]
		mov si, word [vbe_oem_product_rev_ptr_offset]
		mov ds, ax
		call print_string
		pop ds

		mov si, prompt_strings.newline
		call print_string

	; Get VBE video mode info.

	mov ax, 0x4F01
	mov di, vbe_mode_block
	mov cx, 0x4101
	and cx, 0xfff
	int 0x10

	; call clear_registers
	; mov si, [vbe_version]
	; mov di, int16_to_str_buffer
	; call int16_to_str
	; mov si, di
	; call print_string

    ret