.equ SYS_READ,  63
.equ SYS_IOCTL, 29
.equ TCGETS,    0x5401
.equ TCSETS,    0x5402
.equ ICANON,    0x0002
.equ ECHO,      0x0008
.equ STDIN,     0

.section .bss
.align 8
orig_termios: .skip 64
raw_termios:  .skip 64
key_buf:      .skip 8

pending_key:  .skip 8
has_pending:  .skip 8

.section .text

.global keyboard_init
keyboard_init:
    stp x29, x30, [sp, #-16]!

    mov x0, #STDIN
    mov x1, #TCGETS
    ldr x2, =orig_termios
    mov x8, #SYS_IOCTL
    svc #0

    ldr x0, =orig_termios
    ldr x1, =raw_termios
    mov x2, #64
kb_copy_loop:
    ldrb w3, [x0], #1
    strb w3, [x1], #1
    subs x2, x2, #1
    bne kb_copy_loop

    ldr x0, =raw_termios
    ldr w1, [x0, #12]
    mov w2, #ICANON
    orr w2, w2, #ECHO
    bic w1, w1, w2
    str w1, [x0, #12]

    mov w1, #0
    strb w1, [x0, #17 + 6]
    strb w1, [x0, #17 + 5]

    mov x0, #STDIN
    mov x1, #TCSETS
    ldr x2, =raw_termios
    mov x8, #SYS_IOCTL
    svc #0

    ldr x0, =has_pending
    mov x1, #0
    str x1, [x0]

    ldp x29, x30, [sp], #16
    ret

.global keyboard_restore
keyboard_restore:
    mov x0, #STDIN
    mov x1, #TCSETS
    ldr x2, =orig_termios
    mov x8, #SYS_IOCTL
    svc #0
    ret

.global keyboard_read
keyboard_read:
    stp x29, x30, [sp, #-16]!

    mov x0, #STDIN
    ldr x1, =key_buf
    mov x2, #1
    mov x8, #SYS_READ
    svc #0

    cmp x0, #1
    bne kb_nothing

    ldr x1, =key_buf
    ldrb w2, [x1]

    cmp w2, #0x0A
    beq kb_check_enter
    cmp w2, #0x0D
    beq kb_check_enter

    ldr x1, =pending_key
    str w2, [x1]
    ldr x1, =has_pending
    mov w3, #1
    str w3, [x1]

    mov w0, #-1
    b kb_read_done

kb_check_enter:
    ldr x1, =has_pending
    ldr w3, [x1]
    cmp w3, #1
    bne kb_nothing

    ldr x1, =pending_key
    ldr w0, [x1]

    ldr x1, =has_pending
    mov w3, #0
    str w3, [x1]

    b kb_read_done

kb_nothing:
    mov w0, #-1

kb_read_done:
    ldp x29, x30, [sp], #16
    ret