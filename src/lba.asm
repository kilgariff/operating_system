lba_strings:

	.header db '=== LBA', 0x0D, 0x0A, 0
	.newline db 0x0D, 0x0A, 0
	.not_supported db 'Error: LBA support is not available', 0x0D, 0x0A, 0
	.supported db 'LBA is available', 0x0D, 0x0A, 0
	.stage2_header db '=== STAGE 2', 0x0D, 0x0A, 0
	.read_success db 'Finished loading stage 2', 0x0D, 0x0A, 0
	.read_failed db 'Error: Failed to load stage 2', 0x0D, 0x0A, 0

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
		dw	stage_2_load_point
		dw	0x07C0
	.lba:
		dd	1		; read mode
		dd	0

setup_lba:

	mov si, lba_strings.header
	call print_string

    mov ah, 0x41
    mov bx, 0x55AA
    mov dl, 0x80

    jnc .lba_supported

    .lba_not_supported:

		mov si, lba_strings.not_supported
		call print_string
		hlt

	.lba_supported:

		mov si, lba_strings.supported
		call print_string

	mov si, lba_strings.newline
	call print_string

    ret

load_stage_2:

	mov si, lba_strings.stage2_header
	call print_string

	mov si, disk_access_packet
	mov ah, 0x42
	mov al, 0x0
	mov dl, 0x80 ; drive number 0 (OR the drive # with 0x80)
	int 0x13

	jnc .read_succeeded

	.read_failed:

		mov si, lba_strings.read_failed
		call print_string
		hlt

	.read_succeeded:

		mov si, lba_strings.read_success
		call print_string
	
	mov si, lba_strings.newline
	call print_string
    ret