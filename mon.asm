[bits 16]
[org 0x7C00]

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    jmp main

main:
    mov si, prompt
    call puts

    mov di, buffer
    call readline

    mov si, crlf
    call puts

    mov si, buffer
    mov di, cmd_help
    call strcmp
    jz .do_help

    mov si, buffer
    mov di, cmd_rhc
    call strcmp
    jz .do_rhc

    mov si, buffer
    mov di, cmd_run
    call strcmp
    jz .do_run

    mov si, msg_unknown
    call puts
    jmp main

.do_help:
    mov si, msg_help
    call puts
    jmp main

.do_rhc:
    call rhc
    jmp main

.do_run:
    call run
    jmp main

hang:
    hlt
    jmp hang

putc:
    mov ah, 0x0E
    int 0x10
    ret

getc:
    mov ah, 0x00
    int 0x16
    ret

puts:
    mov al, [si]
    test al, al
    jz .done
    call putc
    inc si
    jmp puts
.done:
    ret

readline:
.loop:
    call getc
    cmp al, 0x0D
    je .enter
    cmp al, 0x08
    je .backspace
    cmp al, 0x20
    jb .loop
    mov [di], al
    inc di
    call putc
    jmp .loop

.backspace:
    cmp di, buffer
    jbe .loop
    dec di
    mov al, 0x08
    call putc
    mov al, ' '
    call putc
    mov al, 0x08
    call putc
    jmp .loop

.enter:
    mov byte [di], 0
    ret

strcmp:
.loop:
    mov al, [si]
    cmp al, [di]
    jne .not_equal
    test al, al
    jz .equal
    inc si
    inc di
    jmp .loop
.equal:
    ret
.not_equal:
    or al, 1
    ret

rhc:
    mov si, msg_hex
    call puts
    mov di, 0x9000

.r_loop:
    call getc
    cmp al, 0x0D
    je .r_done
    cmp al, ' '
    je .r_loop

    push ax
    call putc
    pop ax

    call hex_to_val
    mov cl, al
    shl cl, 4

.r_second:
    call getc
    cmp al, ' '
    je .r_second

    push ax
    call putc
    pop ax

    call hex_to_val
    or cl, al

    mov [di], cl
    inc di
    mov al, ' '
    call putc
    jmp .r_loop

.r_done:
    mov si, crlf
    call puts
    ret

hex_to_val:
    cmp al, '9'
    jbe .digit
    and al, 0xDF
    sub al, 'A' - 10
    ret
.digit:
    sub al, '0'
    ret

run:
    call 0x9000
    mov si, crlf
    call puts
    ret

prompt:      db '/ ', 0
crlf:        db 13, 10, 0
cmd_help:    db 'help', 0
cmd_rhc:     db 'rhc', 0
cmd_run:     db 'run', 0
msg_unknown: db 'syntax error', 13, 10, 0
msg_help:    db 'Commands: help, rhc, run', 13, 10, 0
msg_hex:     db 'hex> ', 0
buffer:      times 64 db 0

times 510-($-$$) db 0
dw 0xAA55
