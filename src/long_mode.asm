GDT64:                           ; Global Descriptor Table (64-bit).
    .Null: equ $ - GDT64         ; The null descriptor.
    dw 0                         ; Limit (low).
    dw 0                         ; Base (low).
    db 0                         ; Base (middle)
    db 0                         ; Access.
    db 0                         ; Granularity.
    db 0                         ; Base (high).
    .Code: equ $ - GDT64         ; The code descriptor.
    dw 0                         ; Limit (low).
    dw 0                         ; Base (low).
    db 0                         ; Base (middle)
    db 10011010b                 ; Access (exec/read).
    db 00100000b                 ; Granularity.
    db 0                         ; Base (high).
    .Data: equ $ - GDT64         ; The data descriptor.
    dw 0                         ; Limit (low).
    dw 0                         ; Base (low).
    db 0                         ; Base (middle)
    db 10010010b                 ; Access (read/write).
    db 00000000b                 ; Granularity.
    db 0                         ; Base (high).
    .Pointer:                    ; The GDT-pointer.
    dw $ - GDT64 - 1             ; Limit.
    dq GDT64                     ; Base.

enter_long_mode:

    .enable_20_line:
    
        ; Enable A20 line (assume the BIOS method will work for now)

        mov ax, 0x2403
        int 0x15
        jb .a20_not_supported
        cmp ah, 0
        jnz .a20_not_supported

        mov ax, 0x2402
        int 0x15
        jb .a20_not_supported
        cmp ah, 0
        jnz .a20_not_supported

        mov ax, 0x2401
        int 0x15
        jb .a20_not_supported
        cmp ah, 0
        jnz .a20_not_supported

    jmp .setup_paging

    .a20_not_supported:
        ; TODO: Print useful error
        hlt

    .setup_paging:

        ; From:
        ; http://wiki.osdev.org/Setting_Up_Long_Mode

        ; "Basically, what pages you want to set up and how you want 
        ; them to be set up is up to you, but I'd identity map the first
        ; megabyte and then map some high memory to the memory after the
        ; first megabyte, however, this may be pretty difficult to set up
        ; first. So let's identity map the first two megabytes.
        ; We'll set up four tables at 0x1000
        ; (assuming that this is free to use): a PML4T, a PDPT, a PDT and
        ;  a PT. Basically we want to identity map the first two megabytes"

        ; Clear tables

        mov edi, 0x1000    ; Set the destination index to 0x1000.
        mov cr3, edi       ; Set control register 3 to the destination index.
        xor eax, eax       ; Nullify the A-register.
        mov ecx, 4096      ; Set the C-register to 4096.
        rep stosd          ; Clear the memory.
        mov edi, cr3       ; Set the destination index to control register 3.

        ; "Now that the page are clear we're going to set up the tables,
        ; the page tables are going to be located at these addresses:"
        ; PML4T - 0x1000.
        ; PDPT - 0x2000.
        ; PDT - 0x3000.
        ; PT - 0x4000.

        ; Set up tables

        mov DWORD [edi], 0x2003      ; Set the uint32_t at the destination index to 0x2003.
        add edi, 0x1000              ; Add 0x1000 to the destination index.
        mov DWORD [edi], 0x3003      ; Set the uint32_t at the destination index to 0x3003.
        add edi, 0x1000              ; Add 0x1000 to the destination index.
        mov DWORD [edi], 0x4003      ; Set the uint32_t at the destination index to 0x4003.
        add edi, 0x1000              ; Add 0x1000 to the destination index.

        ; "If you haven't noticed already, I used a three.
        ; This simply means that the first two bits should be set.
        ; These bits indicate that the page is present and that it is
        ; readable as well as writable."

        ; "Now all that's left to do is identity map the first two megabytes:"
        ; This involves populating the page table with pages.
        ; Each page has flags from bytes 0 to 11, then the page address in 12 to 31.
        
        mov ebx, 0x00000003          ; Set the B-register to 0x00000003.
        mov ecx, 512                 ; Set the C-register to 512 (512 * page size is 2MiB)
        
        .set_entry:

            mov DWORD [edi], ebx         ; Set the uint32_t at the destination index to the B-register.
            add ebx, 0x1000              ; Add 0x1000 to the B-register.
            add edi, 8                   ; Add eight to the destination index.
            loop .set_entry              ; Set the next entry.

        ; "Now we should enable PAE-paging by setting the PAE-bit in the fourth
        ; control register:"

        mov eax, cr4                 ; Set the A-register to control register 4.
        or eax, 1 << 5               ; Set the PAE-bit, which is the 6th bit (bit 5).
        mov cr4, eax                 ; Set control register 4 to the A-register.

        ; (As we're going straight from real mode...)
        ; "There's not much left to do. We should set the long mode bit in the
        ; EFER MSR and then we should enable paging and protected mode and then
        ; we are in compatibility mode (which is part of long mode)."

        ; "So we first set the LM-bit:"

        mov ecx, 0xC0000080          ; Set the C-register to 0xC0000080, which is the EFER MSR.
        rdmsr                        ; Read from the model-specific register.
        or eax, 1 << 8               ; Set the LM-bit which is the 9th bit (bit 8).
        wrmsr                        ; Write to the model-specific register.

        ; "Enabling paging and protected mode:"

        cli                          ; Clear interrupt flags (disable interrupts)
        mov eax, cr0                 ; Set the A-register to control register 0.
        or eax, 1 << 31 | 1 << 0     ; Set the PG-bit, which is the 31nd bit, and the PM-bit, which is the 0th bit.
        mov cr0, eax                 ; Set control register 0 to the A-register.

        ; "Now we're in compatibility mode"

        ; "Now that we're in long mode, there's one issue left: we are in the 32-bit
        ; compatibility submode and we actually wanted to enter 64-bit long mode.
        ; This isn't a hard thing to do. We should load just load a GDT with the
        ; 64-bit flags set in the code and data selectors."

        ; "Our GDT (see chapter 4.8.1 and 4.8.2 of the AMD64 Architecture Programmer's
        ; Manual Volume 2) should look like this:"

        ; "Now the only thing left to do is load it and make the jump to 64-bit:"

        lgdt [GDT64.Pointer]         ; Load the 64-bit global descriptor table.
        jmp GDT64.Code:realm_64       ; Set the code segment and enter 64-bit long mode.

    ret

; Use 64-bit.
[BITS 64]
realm_64:

    jmp main64

[BITS 16]