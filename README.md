# csa-final-project

section .data
    header db 10, "========================================", 10
           db "  INVENTORY MANAGEMENT SYSTEM", 10
           db "========================================", 10, 10
    header_len equ $ - header

    menu_title db "Options presented to the user:", 10
    menu_title_len equ $ - menu_title

    option1 db "1. Add Item", 10
    option1_len equ $ - option1

    option2 db "2. Update Item", 10
    option2_len equ $ - option2

    option3 db "3. Delete Item", 10
    option3_len equ $ - option3

    option4 db "4. Search Item", 10
    option4_len equ $ - option4

    option5 db "5. Display Inventory", 10
    option5_len equ $ - option5

    option6 db "6. Generate Report", 10
    option6_len equ $ - option6

    option7 db "7. Exit", 10, 10
    option7_len equ $ - option7

    footer db "========================================", 10
           db "Enter your choice (1-7): "
    footer_len equ $ - footer

section .bss
    choice resb 2

section .text
    global _start

_start:
    mov eax, 4
    mov ebx, 1
    mov ecx, header
    mov edx, header_len
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, menu_title
    mov edx, menu_title_len
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, option1
    mov edx, option1_len
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, option2
    mov edx, option2_len
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, option3
    mov edx, option3_len
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, option4
    mov edx, option4_len
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, option5
    mov edx, option5_len
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, option6
    mov edx, option6_len
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, option7
    mov edx, option7_len
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, footer
    mov edx, footer_len
    int 0x80

    mov eax, 3
    mov ebx, 0
    mov ecx, choice
    mov edx, 2
    int 0x80

    mov eax, 1
    xor ebx, ebx
    int 0x80
