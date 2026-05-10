section .data

;---Title of the system
    header db 0Ah, "========================================", 0Ah
           db "  INVENTORY MANAGEMENT SYSTEM", 0Ah
           db "========================================", 0Ah, 0Ah
    header_len equ $ - header

;---Menu
    menu db "Options presented to the user:", 0Ah
                db "1. Add Item", 0Ah
                db "2. Update Item", 0Ah
                db "3. Delete Item", 0Ah
                db "4. Search Item", 0Ah
                db "5. Display Inventory", 0Ah
                db "6. Generate Report", 0Ah
                db "7. Exit", 0Ah, 0Ah
    menu_len equ $ - menu

    footer db "========================================", 0Ah
           db "Enter your choice (1-7): "
    footer_len equ $ - footer

;---Add Item
    id    db 0Ah, "Enter ID (e.g., 1001): "
    id_len    equ $ - id
    name  db "Enter Name: "
    name_len     equ $ - name
    quantity   db "Enter Quantity: "
    quantity_len     equ $ - quantity
    price   db "Enter Price: "
    price_len     equ $ - price
    
;---Messages
    success    db 0Ah, "[SUCCESS] Record stored!", 0Ah
    success_len      equ $ - success
    error   db 0Ah, "[ERROR] Validation Failed: ID already exists!", 0Ah
    error_len     equ $ - error

;---State Variable
    item_count dd 0 ; START AT 0 (The inventory is now empty by default)
    
section .bss
    choice resb 2
    temp_id resb 8
    
;---The Empty "Array of Structures"
    inventory resb 560  ; We reserve exactly 560 bytes of blank space (10 items * 56 bytes each)

section .text
    global _start

_start:

main_menu:
;---Display for Title of the system
    mov eax, 4
    mov ebx, 1
    mov ecx, header
    mov edx, header_len
    int 80h

;---Display for Main menu
    mov eax, 4
    mov ebx, 1
    mov ecx, menu
    mov edx, menu_len
    int 80h

;---Prompt for Choice
    mov eax, 4
    mov ebx, 1
    mov ecx, footer
    mov edx, footer_len
    int 80h


    mov eax, 3
    mov ebx, 0
    mov ecx, choice
    mov edx, 2
    int 80h
    
    mov al, [choice]
    cmp al, '1'
    je add_item
    cmp al, '7'
    je exit

;---Prompt for Add item
add_item:

    mov eax, 4
    mov ebx, 1
    mov ecx, id
    mov edx, id_len
    int 80h

    mov eax, 3
    mov ebx, 0
    mov ecx, temp_id
    mov edx, 8
    int 80h
    
;---Validate the Uniqueness of the ID
    mov ecx, [item_count]       
    cmp ecx, 0  ;---; If count is 0, the very first item is always unique                  
    je .unique
    
    mov esi, inventory  ; Put start of inventory into ESI
    mov eax, [temp_id]
    
.check_loop:
    mov ebx, [esi]              
    cmp eax, ebx                
    je .duplicate_found          

    add esi, 56                 
    dec ecx                     
    jnz .check_loop
    
.unique:

;---Stored Record in the Inventory
    mov eax, [item_count]
    mov ecx, 56
    mul ecx
    
    mov edi, inventory  ; Step 1: Base Address
    add edi, eax    ; Step 2: Add Offset (EDI now points to empty slot)
    
    mov esi, temp_id
    mov eax, [esi]          
    mov [edi], eax          
    mov eax, [esi+4]        
    mov [edi+4], eax

;---Prompt for name
    mov eax, 4
    mov ebx, 1
    mov ecx, name
    mov edx, name_len
    int 80h
    
    mov eax, 3
    mov ebx, 0
    mov ecx, edi    ; Copy base folder address
    add ecx, 8  ; Jump 8 bytes down for Name
    mov edx, 32
    int 80h
    
;---Prompt for Quantity
    mov eax, 4
    mov ebx, 1
    mov ecx, quantity
    mov edx, quantity_len
    int 80h
    
    mov eax, 3
    mov ebx, 0
    mov ecx, edi                ; Copy base folder address
    add ecx, 40                 ; Jump 40 bytes down for Qty
    mov edx, 8
    int 80h

;---Prompt for Price
    mov eax, 4
    mov ebx, 1
    mov ecx, price
    mov edx, price_len
    int 80h
    
    mov eax, 3
    mov ebx, 0
    mov ecx, edi                ; Copy base folder address
    add ecx, 48                 ; Jump 48 bytes down for Price
    mov edx, 8
    int 80h

;---Increment & Confirm
    mov eax, [item_count]
    inc eax                 
    mov [item_count], eax   

    mov eax, 4
    mov ebx, 1
    mov ecx, success
    mov edx, success_len
    int 80h
    
    jmp main_menu
    
.duplicate_found:
    mov eax, 4
    mov ebx, 1
    mov ecx, error
    mov edx, error_len
    int 80h
    jmp main_menu

;---Prompt for exit program
exit:
    mov eax, 1
    xor ebx, ebx
    int 80h