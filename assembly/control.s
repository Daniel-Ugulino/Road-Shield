.section .text

.equ STEP_DIST, 5
.equ STEP_VEL,  5

.global control

.extern cfg_dist_free
.extern cfg_dist_att
.extern cfg_vel_max

control:
    cmp     w0, #'A'
    b.lt    control_no_upper
    cmp     w0, #'Z'
    b.gt    control_no_upper
    add     w0, w0, #('a' - 'A')
control_no_upper:
    cmp w0, #'w'
    beq increase_max_speed
    cmp w0, #'s'
    beq reduce_max_speed
    cmp w0, #'a'
    beq increase_risk_zone
    cmp w0, #'d'
    beq reduce_risk_zone

    mov w0, #0
    ret

increase_max_speed:
    adr     x9, cfg_vel_max
    ldrb    w10, [x9]
    add     w10, w10, #STEP_VEL
    cmp     w10, #255
    b.le    increase_max_speed_store
    mov     w10, #255
increase_max_speed_store:
    strb    w10, [x9]
    mov     w0, #1
    bl      log_control_action
    mov     w0, #0x01
    ret

reduce_max_speed:
    adr     x9, cfg_vel_max
    ldrb    w10, [x9]
    subs    w10, w10, #STEP_VEL
    b.hs    reduce_max_speed_store
    mov     w10, #0
reduce_max_speed_store:
    strb    w10, [x9]
    mov     w0, #2
    bl      log_control_action
    mov     w0, #0x02
    ret

increase_risk_zone:
    adr     x9, cfg_dist_free
    adr     x10, cfg_dist_att
    ldrb    w11, [x9]
    ldrb    w12, [x10]
    add     w11, w11, #STEP_DIST
    add     w12, w12, #STEP_DIST
    cmp     w11, #255
    b.le    increase_risk_zone_check_att
    mov     w11, #255
increase_risk_zone_check_att:
    cmp     w12, w11
    b.le    increase_risk_zone_store
    mov     w12, w11
increase_risk_zone_store:
    strb    w11, [x9]
    strb    w12, [x10]
    mov     w0, #3
    bl      log_control_action
    mov     w0, #0x03
    ret

reduce_risk_zone:
    adr     x9, cfg_dist_free
    adr     x10, cfg_dist_att
    ldrb    w11, [x9]
    ldrb    w12, [x10]
    subs    w11, w11, #STEP_DIST
    b.hs    reduce_risk_zone_sub_att
    mov     w11, #0
reduce_risk_zone_sub_att:
    subs    w12, w12, #STEP_DIST
    b.hs    reduce_risk_zone_store
    mov     w12, #0
reduce_risk_zone_store:
    cmp     w12, w11
    b.le    reduce_risk_zone_write
    mov     w12, w11
reduce_risk_zone_write:
    strb    w11, [x9]
    strb    w12, [x10]
    mov     w0, #4
    bl      log_control_action
    mov     w0, #0x04
    ret
