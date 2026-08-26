// Envia pacote de configuracao Pi -> FPGA (config_rx.v)
//
//   STX | 0x10 | dist_free | dist_att | vel_max | CHK | ETX
//
// CHK = XOR de TYPE_CFG + 3 campos (sem STX/ETX)

.equ STX,           0x02
.equ ETX,           0x03
.equ TYPE_CFG,      0x10

.section .data
.global cfg_dist_free
.global cfg_dist_att
.global cfg_vel_max
cfg_dist_free:       .byte 100
cfg_dist_att:        .byte 50
cfg_vel_max:         .byte 120

.section .text

// void config_init(void) — envia cfg na UART
.global config_init
config_init:
    stp     x29, x30, [sp, #-16]!

    mov     w0, #STX
    bl      uart_send_byte

    mov     w19, #TYPE_CFG
    mov     w0, w19
    bl      uart_send_byte

    adr     x9, cfg_dist_free
    mov     w13, #0

cfg_send_field:
    cmp     w13, #3
    b.ge    cfg_send_chk

    ldrb    w0, [x9, x13]
    eor     w19, w19, w0
    bl      uart_send_byte

    add     w13, w13, #1
    b       cfg_send_field

cfg_send_chk:
    mov     w0, w19
    bl      uart_send_byte

    mov     w0, #ETX
    bl      uart_send_byte

    ldp     x29, x30, [sp], #16
    ret
