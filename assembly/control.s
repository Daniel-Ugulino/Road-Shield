.section .text

.equ STEP_DIST, 5
.equ STEP_VEL,  5

.global control

.extern cfg_dist_free
.extern cfg_dist_att
.extern cfg_vel_max

control:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    str     x19, [sp, #16]

    orr     w0, w0, #0x20

    cmp     w0, #'w'
    b.eq    increase_max_speed
    cmp     w0, #'s'
    b.eq    reduce_max_speed
    cmp     w0, #'a'
    b.eq    increase_risk_zone
    cmp     w0, #'d'
    b.eq    reduce_risk_zone

    mov     w0, #0
    b       control_ret

increase_max_speed:
    mov     w1, #STEP_VEL
    mov     w19, #0x01
    b       apply_speed

reduce_max_speed:
    mov     w1, #-STEP_VEL
    mov     w19, #0x02

apply_speed:
    adr     x9, cfg_vel_max
    bl      adjust_byte
    b       control_log

increase_risk_zone:
    mov     w1, #STEP_DIST
    mov     w19, #0x03
    b       apply_risk_zone

reduce_risk_zone:
    mov     w1, #-STEP_DIST
    mov     w19, #0x04

apply_risk_zone:
    adr     x9, cfg_dist_free
    bl      adjust_byte
    adr     x9, cfg_dist_att
    bl      adjust_byte

control_log:
    mov     w0, w19
    bl      log_control_action
    mov     w0, w19

control_ret:
    ldr     x19, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret

// [x9] += w1, saturando em 0..255
adjust_byte:
    ldrb    w2, [x9]
    add     w2, w2, w1
    cmp     w2, #255
    mov     w3, #255
    csel    w2, w2, w3, le
    cmp     w2, #0
    csel    w2, w2, wzr, ge
    strb    w2, [x9]
    ret
