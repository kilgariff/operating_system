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

	call setup_cpu_info
	;call cpu_require_long_mode
	call vesa_setup_display

	call vesa_show_modes

	mov cx, 323
	call vesa_print_mode_info

	mov ax, 323
	call vesa_switch_mode

	call enter_long_mode

	;call begin_command_prompt

	hlt

[BITS 64]

main64:

	; jmp .skip_thing
	; .flt_600: dd 1142292480 ; float value 600
	; .skip_thing:

	mov esi, 0

	.main_loop:

		mov ecx, 600
		mov edi, 0x00200000 ; Physical address is 0xE0000000, memory mapped address is 0x00200000 (2 MiB in)

		.draw_row:
			mov ebx, ecx
			mov ecx, 800

			; Lerp (gradient effect)

			; movss xmm0, dword [.flt_600] ; float 600, xmm0 = mem[0],zero,zero,zero
			; mov eax, ecx ; 0 <= ecx < 600

			; cvtsi2ss xmm1, rax ; Convert integer in rax (eax) to float
			; divss xmm1, xmm0 ; Person division
			; movaps xmm0, xmm1 ; Move result into xmm0 (0 <= xmm0 < 1)

			; mov eax, 0xFF ; Goal is to map the xmm0 to (0x00, 0xFF)

			; cvtsi2ss xmm1, rax
			; mulss xmm0, xmm1 ; Perform floating-point multiply
			; cvttss2si rax, xmm0 ; Convert back into unsigned integer, ready for rep stosd to draw the line

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

		add esi, 8
		jmp .main_loop

		hlt
[BITS 16]

times 4096-($-$$) db 0