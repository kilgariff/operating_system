cpu_strings:

    .header db '=== CPU', 0x0D, 0x0A, 0
	.newline db 0xD, 0xA, 0
    .supported db 'CPUID is supported', 0x0D, 0x0A, 0
    .not_supported db 'CPUID is not supported', 0x0D, 0x0A, 0
    .vendor db 'Vendor: ', 0
    .features db 'Features (bitfields): ecx is ', 0
    .and db ' and edx is ', 0
    .long_mode_supported db 'Long mode is supported', 0x0D, 0x0A, 0
    .long_mode_not_supported db 'Long mode is not supported', 0x0D, 0x0A, 0

cpu_info:

    .vendor times 3 dd 0
    db 0x0D, 0x0A, 0
    .features times 2 dd 0
    .supports_long_mode db 0

cpu_features:

    .ecx:

        .sse3      db 0 
        .pclmul    db 1
        .dtes64    db 2
        .monitor   db 3
        .ds_cpl    db 4
        .vmx       db 5
        .smx       db 6
        .est       db 7
        .tm2       db 8
        .ssse3     db 9
        .cid       db 10
        .fma       db 12
        .cx16      db 13 
        .etprd     db 14 
        .pdcm      db 15 
        .pcide     db 17 
        .dca       db 18 
        .sse4_1    db 19 
        .sse4_2    db 20 
        .x2apic    db 21 
        .movbe     db 22 
        .popcnt    db 23 
        .aes       db 25 
        .xsave     db 26 
        .osxsave   db 27 
        .avx       db 28
 
    .edx:

        .fpu        db 0
        .vme        db 1
        .de         db 2
        .pse        db 3
        .tsc        db 4
        .msr        db 5
        .pae        db 6
        .mce        db 7
        .cx8        db 8
        .apic       db 9
        .sep        db 11
        .mtrr       db 12
        .pge        db 13
        .mca        db 14
        .cmov       db 15
        .pat        db 16
        .pse36      db 17
        .psn        db 18
        .clf        db 19
        .dtes       db 21
        .acpi       db 22
        .mmx        db 23
        .fxsr       db 24
        .sse        db 25
        .sse2       db 26
        .ss         db 27
        .htt        db 28
        .tm1        db 29
        .ia64       db 30
        .pbe        db 31

int32_to_str_buffer times 11 db 0

setup_cpu_info:

    ; Print header

    mov si, cpu_strings.header
    call print_string

    ; Check CPUID support

    pushfd
    pushfd
    xor dword [esp], 0x00200000
    popfd
    pushfd
    pop eax
    xor eax, [esp]
    popfd
    and eax, 0x00200000
    jz .not_supported

    ; Inform user that CPUID is supported

    mov si, cpu_strings.supported
    call print_string

    ; Get & print CPU vendor string

    mov eax, 0x0
    cpuid
    mov dword [cpu_info.vendor], ebx
    mov dword [cpu_info.vendor + 4], edx
    mov dword [cpu_info.vendor + 8], ecx

    mov si, cpu_strings.vendor
    call print_string

    mov si, cpu_info.vendor
    call print_string

    ; Get & print CPU feature bitfields (as decimal for now)

    mov eax, 0x1
    cpuid
    mov dword [cpu_info.features], ecx
    mov dword [cpu_info.features + 4], edx

    mov si, cpu_strings.features
    call print_string

    mov esi, [cpu_info.features]
    mov di, int32_to_str_buffer
    call int32_to_str
    mov si, di
    call print_string

    mov si, cpu_strings.and
    call print_string

    mov esi, [cpu_info.features + 4]
    mov di, int32_to_str_buffer
    call int32_to_str
    mov si, di
    call print_string

    mov si, cpu_strings.newline
    call print_string

    ; Detect whether long mode flag is available,
    ; and if it is, check whether long mode is available.

    .check_long_mode:

        mov eax, 0x80000000
        cpuid
        cmp eax, 0x80000001
        jb .no_long_mode

        mov eax, 0x80000001
        cpuid
        test edx, 1 << 29
        jz .no_long_mode

        mov byte [cpu_info.supports_long_mode], 1
        mov si, cpu_strings.long_mode_supported
        call print_string
        jmp .done

        .no_long_mode:

            mov byte [cpu_info.supports_long_mode], 0
            mov si, cpu_strings.long_mode_not_supported
            call print_string

        .done:
            nop

    ; End of 'CPU' section

    mov si, cpu_strings.newline
    call print_string

    ret

    .not_supported:

        mov si, cpu_strings.not_supported
        call print_string
        hlt

cpu_require_long_mode:

    cmp byte [cpu_info.supports_long_mode], 1
    jne .not_supported
    ret

    .not_supported:
        hlt