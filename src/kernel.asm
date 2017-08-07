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
	;call vesa_setup_display

	;mov ax, 261
	;call vesa_switch_mode

	;call enter_long_mode

	call begin_command_prompt

times 5120-($-$$) db 0