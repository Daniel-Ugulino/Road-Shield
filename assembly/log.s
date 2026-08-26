.equ SYS_OPENAT, 56
.equ SYS_WRITE,  64
.equ SYS_CLOSE,  57
.equ AT_FDCWD,   -100

.equ O_WRONLY,   0x0001
.equ O_CREAT,    0x0040
.equ O_APPEND,   0x0400

.equ MODE_0644,  0x1A4

.section .data
log_path: .asciz "uart_log.txt"
newline:  .ascii "\n"

msg_vel_inc:    .ascii "Vel. max aumentada para "
msg_vel_inc_len: .quad . - msg_vel_inc
msg_vel_dec:    .ascii "Vel. max reduzida para "
msg_vel_dec_len: .quad . - msg_vel_dec
msg_vel_unit:   .ascii " km/h"
msg_vel_unit_len: .quad . - msg_vel_unit

msg_risk_inc:   .ascii "Zona de risco aumentada: livre="
msg_risk_inc_len: .quad . - msg_risk_inc
msg_risk_dec:   .ascii "Zona de risco reduzida: livre="
msg_risk_dec_len: .quad . - msg_risk_dec
msg_mid_att:    .ascii " m atencao="
msg_mid_att_len: .quad . - msg_mid_att
msg_mid_unit:   .ascii " m"
msg_mid_unit_len: .quad . - msg_mid_unit

.extern cfg_dist_free
.extern cfg_dist_att
.extern cfg_vel_max

.section .bss
.align 8
log_fd:       .skip 8
log_byte_buf: .skip 8
log_line_buf: .skip 80

.section .text

// void log_init(void) -> abre/cria o arquivo em modo append
.global log_init
log_init:
    stp x29, x30, [sp, #-16]!

    mov x0, #AT_FDCWD
    ldr x1, =log_path
    mov x2, #O_WRONLY
    orr x2, x2, #O_CREAT
    orr x2, x2, #O_APPEND
    mov x3, #MODE_0644
    mov x8, #SYS_OPENAT
    svc #0

    ldr x1, =log_fd
    str x0, [x1]

    ldp x29, x30, [sp], #16
    ret

// void log_write_byte(uint8_t byte) -> byte vem em w0, grava o byte + \n
.global log_write_byte
log_write_byte:
    stp x29, x30, [sp, #-16]!

    ldr x1, =log_byte_buf
    strb w0, [x1]

    ldr x1, =log_fd
    ldr x0, [x1]
    ldr x1, =log_byte_buf
    mov x2, #1
    mov x8, #SYS_WRITE
    svc #0

    ldr x1, =log_fd
    ldr x0, [x1]
    ldr x1, =newline
    mov x2, #1
    mov x8, #SYS_WRITE
    svc #0

    ldp x29, x30, [sp], #16
    ret

// void log_write(const char *buf, size_t len) — x0=buf, x1=len
.global log_write
log_write:
    stp     x29, x30, [sp, #-32]!
    stp     x0, x1, [sp, #16]

    ldr     x2, =log_fd
    ldr     x0, [x2]
    ldp     x1, x2, [sp, #16]
    mov     x8, #SYS_WRITE
    svc     #0

    ldr     x2, =log_fd
    ldr     x0, [x2]
    ldr     x1, =newline
    mov     x2, #1
    mov     x8, #SYS_WRITE
    svc     #0

    ldp     x29, x30, [sp], #32
    ret

// copia w3 bytes de [x2] para [x1]; retorna x1 avancado
log_copy_n:
    cbz     w3, log_copy_n_done
log_copy_n_loop:
    ldrb    w4, [x2], #1
    strb    w4, [x1], #1
    subs    w3, w3, #1
    b.ne    log_copy_n_loop
log_copy_n_done:
    ret

// w0 = 0..255, x1 = dest; retorna x1 avancado
log_format_byte:
    mov     w2, w0

    mov     w4, #100
    udiv    w5, w2, w4
    msub    w2, w5, w4, w2
    mov     w4, #10
    udiv    w6, w2, w4
    msub    w7, w6, w4, w2

    cbz     w5, log_format_byte_no_hund
    add     w5, w5, #'0'
    strb    w5, [x1], #1
    b       log_format_byte_tens

log_format_byte_no_hund:
    cbz     w6, log_format_byte_ones

log_format_byte_tens:
    add     w6, w6, #'0'
    strb    w6, [x1], #1

log_format_byte_ones:
    add     w7, w7, #'0'
    strb    w7, [x1], #1
    ret

.global log_control_action
log_control_action:
    stp     x29, x30, [sp, #-32]!
    stp     x19, x20, [sp, #16]

    mov     w19, w0
    adr     x20, log_line_buf
    mov     x1, x20

    cmp     w19, #1
    b.eq    log_action_vel_inc
    cmp     w19, #2
    b.eq    log_action_vel_dec
    cmp     w19, #3
    b.eq    log_action_risk_inc
    cmp     w19, #4
    b.eq    log_action_risk_dec
    b       log_action_done

log_action_vel_inc:
    ldr     x2, =msg_vel_inc
    ldr     x3, =msg_vel_inc_len
    ldr     w3, [x3]
    bl      log_copy_n
    b       log_action_vel_value

log_action_vel_dec:
    ldr     x2, =msg_vel_dec
    ldr     x3, =msg_vel_dec_len
    ldr     w3, [x3]
    bl      log_copy_n

log_action_vel_value:
    adr     x9, cfg_vel_max
    ldrb    w0, [x9]
    bl      log_format_byte
    ldr     x2, =msg_vel_unit
    ldr     x3, =msg_vel_unit_len
    ldr     w3, [x3]
    bl      log_copy_n
    b       log_action_emit

log_action_risk_inc:
    ldr     x2, =msg_risk_inc
    ldr     x3, =msg_risk_inc_len
    ldr     w3, [x3]
    bl      log_copy_n
    b       log_action_risk_values

log_action_risk_dec:
    ldr     x2, =msg_risk_dec
    ldr     x3, =msg_risk_dec_len
    ldr     w3, [x3]
    bl      log_copy_n

log_action_risk_values:
    adr     x9, cfg_dist_free
    ldrb    w0, [x9]
    bl      log_format_byte
    ldr     x2, =msg_mid_att
    ldr     x3, =msg_mid_att_len
    ldr     w3, [x3]
    bl      log_copy_n
    adr     x9, cfg_dist_att
    ldrb    w0, [x9]
    bl      log_format_byte
    ldr     x2, =msg_mid_unit
    ldr     x3, =msg_mid_unit_len
    ldr     w3, [x3]
    bl      log_copy_n

log_action_emit:
    sub     x1, x1, x20
    mov     x0, x20
    bl      log_write

log_action_done:
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret

// void log_close(void)
.global log_close
log_close:
    ldr x1, =log_fd
    ldr x0, [x1]
    mov x8, #SYS_CLOSE
    svc #0
    ret