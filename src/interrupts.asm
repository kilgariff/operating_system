;
; This IDT structure is AMD64-specific.
; http://wiki.osdev.org/Interrupt_Descriptor_Table
;

IDT64:
    .offset_1 dw 0
    .selector dw 0
    .interrupt_stack_table db 0
    .type_and_attributes db 0
    .offset_2 dw 0
    .offset_3 dd 0
    .zero dd 0
    .Pointer:                    ; The IDT-pointer.
    dw $ - IDT64 - 1             ; Limit.
    dq IDT64                     ; Base.