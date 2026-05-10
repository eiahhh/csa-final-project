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

;---Update Item
    update_id_prompt db 0Ah, "Enter Item ID to Update: "
    update_id_len    equ $ - update_id_prompt
    update_qty_prompt db "Enter new Quantity: "
    update_qty_len   equ $ - update_qty_prompt
    update_price_prompt db "Enter new Price: "
    update_price_len equ $ - update_price_prompt
    update_success   db 0Ah, "[SUCCESS] Item updated!", 0Ah
    update_success_len equ $ - update_success
    not_found        db 0Ah, "[ERROR] Item not found!", 0Ah
    not_found_len    equ $ - not_found

;---Delete Item
    delete_id_prompt db 0Ah, "Enter Item ID to Delete: "
    delete_id_len    equ $ - delete_id_prompt
    delete_success   db 0Ah, "[SUCCESS] Item deleted!", 0Ah
    delete_success_len equ $ - delete_success

;---Search Item
    search_id_prompt db 0Ah, "Enter Item ID to Search: "
    search_id_len    equ $ - search_id_prompt
    
    disp_id          db 0Ah, "ID: "
    disp_id_len      equ $ - disp_id
    disp_name        db 0Ah, "Name: "
    disp_name_len    equ $ - disp_name
    disp_qty         db 0Ah, "Quantity: "
    disp_qty_len     equ $ - disp_qty
    disp_price       db 0Ah, "Price: "
    disp_price_len   equ $ - disp_price

;---State Variable
    item_count dd 0 ; START AT 0 (The inventory is now empty by default)
    
section .bss
    choice resb 2
    temp_id resb 8
    search_id resb 8
    delete_id resb 8
    
;---The Empty "Array of Structures"
    inventory resb 560  ; We reserve exactly 560 bytes of blank space (10 items * 56 bytes each)

section .text
    global _start

compute_len:
    push esi
    xor edx, edx
.len_loop:
    cmp byte [esi], 0Ah
    je .len_done
    cmp byte [esi], 0
    je .len_done
    inc esi
    inc edx
    jmp .len_loop
.len_done:
    pop esi
    ret


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
    cmp al, '2'
    je update_item
    cmp al, '3'
    je delete_item
    cmp al, '4' ;
    je search_item ;
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

;---Prompt for Update Item
update_item:

;---Prompt for Item ID to Update
    mov eax, 4
    mov ebx, 1
    mov ecx, update_id_prompt
    mov edx, update_id_len
    int 80h

    mov eax, 3
    mov ebx, 0
    mov ecx, search_id
    mov edx, 8
    int 80h

;---Search for the Item by ID
    mov ecx, [item_count]
    cmp ecx, 0                  ; If count is 0, no items to update
    je .update_not_found

    mov esi, inventory          ; Put start of inventory into ESI
    mov eax, [search_id]        ; Load the search ID for comparison

.update_check_loop:
    mov ebx, [esi]              ; Load current record's ID
    cmp eax, ebx                ; Compare with search ID
    je .update_found             ; If match, jump to update

    add esi, 56                 ; Move to next record
    dec ecx                     ; Decrement counter
    jnz .update_check_loop

.update_not_found:
    mov eax, 4
    mov ebx, 1
    mov ecx, not_found
    mov edx, not_found_len
    int 80h
    jmp main_menu

.update_found:
;---Prompt for new Quantity
    mov eax, 4
    mov ebx, 1
    mov ecx, update_qty_prompt
    mov edx, update_qty_len
    int 80h

    mov eax, 3
    mov ebx, 0
    mov ecx, esi                ; Copy base address of found record
    add ecx, 40                 ; Jump 40 bytes down for Qty
    mov edx, 8
    int 80h

;---Prompt for new Price
    mov eax, 4
    mov ebx, 1
    mov ecx, update_price_prompt
    mov edx, update_price_len
    int 80h

    mov eax, 3
    mov ebx, 0
    mov ecx, esi                ; Copy base address of found record
    add ecx, 48                 ; Jump 48 bytes down for Price
    mov edx, 8
    int 80h

;---Confirm Update
    mov eax, 4
    mov ebx, 1
    mov ecx, update_success
    mov edx, update_success_len
    int 80h

    jmp main_menu

;---Prompt for Delete Item
delete_item:

;---Prompt for Item ID to Delete
    mov eax, 4
    mov ebx, 1
    mov ecx, delete_id_prompt
    mov edx, delete_id_len
    int 80h

    mov eax, 3
    mov ebx, 0
    mov ecx, delete_id
    mov edx, 8
    int 80h

;---Search for the Item by ID
    mov ecx, [item_count]
    cmp ecx, 0                  ; If count is 0, no items to delete
    je .delete_not_found

    mov esi, inventory
    mov eax, [delete_id]

.delete_check_loop:
    mov ebx, [esi]
    cmp eax, ebx
    je .delete_found

    add esi, 56
    dec ecx
    jnz .delete_check_loop

.delete_not_found:
    mov eax, 4
    mov ebx, 1
    mov ecx, not_found
    mov edx, not_found_len
    int 80h
    jmp main_menu

.delete_found:
;---Shift records forward to fill the gap
    mov edi, esi                ; EDI = record to delete
    add esi, 56                 ; ESI = next record
    dec ecx                     ; Remaining items after found one
    cmp ecx, 0
    je .delete_shift_done

.delete_shift_loop:
    push ecx                    ; Save outer counter
    mov ecx, 56                 ; 56 bytes per record

.copy_byte:
    mov al, [esi]
    mov [edi], al
    inc esi
    inc edi
    dec ecx
    jnz .copy_byte

    pop ecx
    dec ecx
    jnz .delete_shift_loop

.delete_shift_done:
;---Decrement & Confirm
    mov eax, [item_count]
    dec eax
    mov [item_count], eax

    mov eax, 4
    mov ebx, 1
    mov ecx, delete_success
    mov edx, delete_success_len
    int 80h

    jmp main_menu

;---Search Item
search_item:

    mov eax, 4
    mov ebx, 1
    mov ecx, search_id_prompt
    mov edx, search_id_len
    int 80h

    mov eax, 3
    mov ebx, 0
    mov ecx, search_id
    mov edx, 8
    int 80h

    mov ecx, [item_count]
    cmp ecx, 0
    je .search_not_found

    mov esi, inventory
    mov eax, [search_id]

.search_check_loop:
    mov ebx, [esi]
    cmp eax, ebx
    je .search_found

    add esi, 56
    dec ecx
    jnz .search_check_loop

.search_not_found:
    mov eax, 4
    mov ebx, 1
    mov ecx, not_found
    mov edx, not_found_len
    int 80h
    jmp main_menu

.search_found:

    ; --- Print "ID: "
    mov eax, 4
    mov ebx, 1
    mov ecx, disp_id
    mov edx, disp_id_len
    int 80h

    ; --- Print Actual ID
    call compute_len            ; ESI already at record base; EDX = actual length
    mov eax, 4
    mov ebx, 1
    mov ecx, esi
    int 80h

    ; --- Print "Name: "
    mov eax, 4
    mov ebx, 1
    mov ecx, disp_name
    mov edx, disp_name_len
    int 80h

    ; --- Print Actual Name
    add esi, 8                  ; point ESI to name field
    call compute_len            ; EDX = actual length of name
    mov eax, 4
    mov ebx, 1
    mov ecx, esi
    int 80h
    sub esi, 8                  ; restore ESI to record base

    ; --- Print "Quantity: "
    mov eax, 4
    mov ebx, 1
    mov ecx, disp_qty
    mov edx, disp_qty_len
    int 80h

    ; --- Print Actual Quantity
    add esi, 40                 ; point ESI to quantity field
    call compute_len            ; EDX = actual length of quantity
    mov eax, 4
    mov ebx, 1
    mov ecx, esi
    int 80h
    sub esi, 40                 ; restore ESI to record base

    ; --- Print "Price: "
    mov eax, 4
    mov ebx, 1
    mov ecx, disp_price
    mov edx, disp_price_len
    int 80h

    ; --- Print Actual Price
    add esi, 48                 ; point ESI to price field
    call compute_len            ; EDX = actual length of price
    mov eax, 4
    mov ebx, 1
    mov ecx, esi
    int 80h
    sub esi, 48                 ; restore ESI to record base

    jmp main_menu

;---Prompt for exit program
exit:
    mov eax, 1
    xor ebx, ebx
    int 80h