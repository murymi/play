[bits 16]
[org 0x7c00]
mov [boot_drive], dl

mov bp, 0x9000
mov sp, bp


call load_kernel
mov bx, hello
call print_string

call switch_to_pm
;mov bx, hello
;call print_string


.forever1:
    hlt
jmp .forever1


print_string:
    mov ah, 0x0e
.print:
    mov al, [bx]
    cmp al, 0
    je .finish
    int 0x10
    inc bx
    jmp .print
.finish:
    ret

;load DH sectors to ES : BX from drive DL
disk_load:
    push dx
    mov ah, 0x02
    mov al, dh
    mov ch, 0x00
    mov dh, 0x00
    mov cl, 0x02
    int 0x13
    jc disk_error
    pop dx
    cmp dh, al
    jne disk_error
    ret
disk_error:
    mov bx, DISK_ERROR_MSG
    call print_string
    .hang:
    hlt
    jmp .hang


load_kernel:
    mov bx, loading
    call print_string
    mov bx, kernel_offset
    mov dh, 15
    mov dl, [boot_drive]
    call disk_load
    ret

; GDT
gdt_start:
    gdt_null:
        dd 0x0
        dd 0x0
    gdt_code:
        dw 0xffff
        dw 0x0
        db 0x0
        db 10011010b
        db 11001111b
        db 0x0
    gdt_data:
        dw 0xffff
        dw 0x0
        db 0x0
        db 10010010b
        db 11001111b
        db 0x0
gdt_end:

gdt_descriptor: 
    dw gdt_end - gdt_start - 1
    dd gdt_start

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

[bits 16]
switch_to_pm:
    cli

    lgdt [gdt_descriptor]
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax

    ;;mov bx, moving
    ;;call print_string

    jmp 0x8:init_pm


; Variables 
boot_drive: db 0
DISK_ERROR_MSG db "Disk read error !" , 0
hello: db "kernel load succesfull...", 0
loading: db "Loading kernel...", 13, 10, 0
moving: db "moving to proteted mode", 13, 10, 0
kernel_offset equ 0x1000

[bits 32]
video_mem equ 0xb8000
white_on_black equ 0x0f

print_string_pm:
    pusha
    mov edx, video_mem
    print_loop:
    mov al, [ebx]
    mov ah, white_on_black

    cmp al, 0
    je end_print_loop

    mov [edx], ax

    add ebx, 1
    add edx, 2

    jmp print_loop
    
    end_print_loop:
    popa
    ret

[bits 32]
init_pm:
    ;jmp $
    mov ax, 0x10
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ebp, 0x90000
    mov esp, ebp
    call BEGIN_PM

[bits 32]
protect: db "we are so in!!", 0
BEGIN_PM:
    mov ebx, protect
    call print_string_pm
    
    call kernel_offset
.forever:
    hlt
jmp .forever

times 510 - ($ - $$) db 0
dw 0xaa55