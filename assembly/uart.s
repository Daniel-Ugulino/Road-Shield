.equ SYS_OPENAT,  56
.equ SYS_READ,    63
.equ SYS_WRITE,   64
.equ SYS_IOCTL,   29
.equ AT_FDCWD,    -100
.equ O_RDWR,      0x0002
.equ O_NOCTTY,    0x0100
.equ O_NONBLOCK,  0x0800
.equ TCGETS,      0x5401
.equ TCSETS,      0x5402

.section .data
uart_path: .asciz "/dev/serial0"

.section .bss
.align 8
uart_fd:       .skip 8
uart_termios:  .skip 64

.section .text

.global uart_open
uart_open:
    stp x29, x30, [sp, #-16]!

    mov x0, #AT_FDCWD
    ldr x1, =uart_path
    mov x2, #O_RDWR
    orr x2, x2, #O_NOCTTY
    orr x2, x2, #O_NONBLOCK      // nao bloqueia o read se nao tiver dado
    mov x3, #0
    mov x8, #SYS_OPENAT
    svc #0

    ldr x1, =uart_fd
    str x0, [x1]

    ldp x29, x30, [sp], #16
    ret

.global uart_configure
uart_configure:
    stp x29, x30, [sp, #-16]!

    ldr x1, =uart_fd
    ldr x0, [x1]
    mov x1, #TCGETS
    ldr x2, =uart_termios
    mov x8, #SYS_IOCTL
    svc #0

    ldr x0, =uart_termios
    mov w1, #0
    str w1, [x0, #0]         // c_iflag = 0
    str w1, [x0, #12]        // c_lflag = 0

    strb w1, [x0, #17 + 6]   // VMIN = 0
    strb w1, [x0, #17 + 5]   // VTIME = 0

    ldr x1, =uart_fd
    ldr x0, [x1]
    mov x1, #TCSETS
    ldr x2, =uart_termios
    mov x8, #SYS_IOCTL
    svc #0

    ldp x29, x30, [sp], #16
    ret

.global uart_send_byte
uart_send_byte:
    stp x29, x30, [sp, #-16]!

    strb w0, [sp, #-16]!

    ldr x1, =uart_fd
    ldr x0, [x1]
    mov x1, sp
    mov x2, #1
    mov x8, #SYS_WRITE
    svc #0

    add sp, sp, #16
    ldp x29, x30, [sp], #16
    ret

.global uart_read_byte
uart_read_byte:
    stp x29, x30, [sp, #-16]!

    sub sp, sp, #16

    ldr x1, =uart_fd
    ldr x0, [x1]
    mov x1, sp
    mov x2, #1
    mov x8, #SYS_READ
    svc #0

    cmp x0, #1
    bne uart_read_nothing

    ldrb w0, [sp]
    b uart_read_done

uart_read_nothing:
    mov w0, #-1

uart_read_done:
    add sp, sp, #16
    ldp x29, x30, [sp], #16
    ret