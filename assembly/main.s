.equ SYS_EXIT,      93
.equ SYS_NANOSLEEP, 101

.section .data
sleep_spec: .quad 0, 10000000

.section .text
.global _start

_start:
    bl keyboard_init
    bl log_init
/*  
*   bl uart_open
*   bl uart_configure
*   bl config_init
*/
    bl ui_init

main_loop:
    bl keyboard_read

    cmp w0, #-1
    beq no_key

    mov w19, w0

    cmp w19, #'q'
    beq quit

    bl control

    cmp w0, #0
    beq no_key

    mov w20, w0
/*
*   bl uart_send_byte
*/
    mov w0, w20
    bl ui_show_command
    bl ui_show_config

no_key:
    mov x0, #0
    ldr x1, =sleep_spec
    mov x2, #0
    mov x8, #SYS_NANOSLEEP
    svc #0

    b main_loop

quit:
    bl keyboard_restore
    bl ui_restore
    bl log_close
    mov x0, #0
    mov x8, #SYS_EXIT
    svc #0