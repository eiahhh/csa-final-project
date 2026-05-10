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

;---Generate Report
    report_header db 0Ah, "=== INVENTORY REPORT ===", 0Ah
    report_header_len equ $ - report_header
    total_value_msg db "Total Stock Value: "
    total_value_msg_len equ $ - total_value_msg
    low_stock_msg db 0Ah, "Low Stock Items (Quantity < 5): ", 0Ah
    low_stock_msg_len equ $ - low_stock_msg
    no_low_stock db "None", 0Ah
    no_low_stock_len equ $ - no_low_stock
    low_stock_item db "ID: "
    low_stock_item_len equ $ - low_stock_item
    newline db 0Ah
    newline_len equ 1

LOW_STOCK_THRESHOLD equ 5

;---Exit
    exit_msg db 0Ah, "========================================", 0Ah
             db "  Data saved successfully. Goodbye!", 0Ah
             db "========================================", 0Ah
    exit_msg_len equ $ - exit_msg
    save_err_msg db 0Ah, "[ERROR] Could not save data!", 0Ah
    save_err_msg_len equ $ - save_err_msg
    filename db "inventory.dat", 0
    separator db ","
    separator_len equ 1

;---State Variable
    item_count dd 0 ; START AT 0 (The inventory is now empty by default)
    
section .bss
    choice resb 2
    temp_id resb 8
    search_id resb 8
    delete_id resb 8
    
;---The Empty "Array of Structures"
    inventory resb 560  ; We reserve exactly 560 bytes of blank space (10 items * 56 bytes each)

    num_buffer resb 16 ; for report calculations

    file_fd resd 1

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

;---Convert string to integer
; Input: ESI = pointer to string
; Output: EAX = integer value
atoi:
    xor eax, eax
.loop:
    movzx ebx, byte [esi]
    cmp bl, '0'
    jb .done
    cmp bl, '9'
    ja .done
    cmp bl, 0Ah  ; newline
    je .done
    sub bl, '0'
    imul eax, 10
    add eax, ebx
    inc esi
    jmp .loop
.done:
    ret

;---Convert integer to string
; Input: EAX = number
; Output: num_buffer contains the string, EDI points to start
itoa:
    mov edi, num_buffer + 15
    mov byte [edi], 0  ; null terminate
    dec edi
    mov byte [edi], 0Ah  ; newline
    dec edi
    mov ecx, 10
.itoa_loop:
    xor edx, edx
    div ecx
    add dl, '0'
    mov [edi], dl
    dec edi
    test eax, eax
    jnz .itoa_loop
    inc edi  ; point to first digit
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
    cmp al, '5'
    je display_inventory
    cmp al, '6'
    je generate_report
    cmp al, '7'
    je exit

;---Display Inventory (stub)
display_inventory:
    jmp main_menu

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

;---Generate Report
generate_report:
    ; Print report header
    mov eax, 4
    mov ebx, 1
    mov ecx, report_header
    mov edx, report_header_len
    int 80h

    ; Print low stock message
    mov eax, 4
    mov ebx, 1
    mov ecx, low_stock_msg
    mov edx, low_stock_msg_len
    int 80h

    ; Initialize total_value = 0 (EDI)
    xor edi, edi

    ; Initialize low_stock_count = 0 (EBP)
    xor ebp, ebp

    mov ecx, [item_count]
    cmp ecx, 0
    je .no_items

    mov esi, inventory

.item_loop:
    ; Convert quantity to integer
    push esi
    add esi, 40  ; quantity field
    call atoi
    mov ebx, eax  ; EBX = quantity
    pop esi

    ; Convert price to integer
    push esi
    add esi, 48  ; price field
    call atoi
    ; EAX = price

    ; Calculate value = quantity * price
    imul eax, ebx
    add edi, eax  ; total_value += value

    ; Check for low stock
    cmp ebx, LOW_STOCK_THRESHOLD
    jge .not_low

    ; Low stock item found
    inc ebp

    ; Print "ID: "
    push esi
    mov eax, 4
    mov ebx, 1
    mov ecx, low_stock_item
    mov edx, low_stock_item_len
    int 80h

    ; Print actual ID
    call compute_len
    mov eax, 4
    mov ebx, 1
    mov ecx, esi
    int 80h

    ; Print newline
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, newline_len
    int 80h

    pop esi

.not_low:
    add esi, 56  ; next item
    dec ecx
    jnz .item_loop

    ; Check if no low stock items
    cmp ebp, 0
    jne .print_total

    ; Print "None"
    mov eax, 4
    mov ebx, 1
    mov ecx, no_low_stock
    mov edx, no_low_stock_len
    int 80h

.print_total:
    ; Print total value message
    mov eax, 4
    mov ebx, 1
    mov ecx, total_value_msg
    mov edx, total_value_msg_len
    int 80h

    ; Convert total_value (EDI) to string
    mov eax, edi
    call itoa

    ; Print the number
    mov edx, num_buffer + 16
    sub edx, edi  ; length
    mov eax, 4
    mov ebx, 1
    mov ecx, edi
    int 80h

.no_items:
    jmp main_menu

;---Exit: Save data, display message, terminate
exit:
    ; --- Open file for writing (create/truncate) ---
    mov eax, 5              ; sys_open
    mov ebx, filename
    mov ecx, 0241h          ; O_WRONLY | O_CREAT | O_TRUNC
    mov edx, 0644o          ; permissions rw-r--r--
    int 80h

    cmp eax, 0
    jl .save_error           ; if negative, file open failed

    mov [file_fd], eax       ; store file descriptor

    ; --- Loop through inventory and write each record ---
    mov ecx, [item_count]
    cmp ecx, 0
    je .close_file           ; nothing to save

    mov esi, inventory

.save_loop:
    push ecx                 ; preserve loop counter

    ; Write ID
    call compute_len         ; ESI = ID field, EDX = length
    mov eax, 4
    mov ebx, [file_fd]
    mov ecx, esi
    int 80h

    ; Write separator ","
    mov eax, 4
    mov ebx, [file_fd]
    mov ecx, separator
    mov edx, separator_len
    int 80h

    ; Write Name
    push esi
    add esi, 8               ; offset to Name field
    call compute_len
    mov eax, 4
    mov ebx, [file_fd]
    mov ecx, esi
    int 80h
    pop esi

    ; Write separator
    mov eax, 4
    mov ebx, [file_fd]
    mov ecx, separator
    mov edx, separator_len
    int 80h

    ; Write Quantity
    push esi
    add esi, 40              ; offset to Quantity field
    call compute_len
    mov eax, 4
    mov ebx, [file_fd]
    mov ecx, esi
    int 80h
    pop esi

    ; Write separator
    mov eax, 4
    mov ebx, [file_fd]
    mov ecx, separator
    mov edx, separator_len
    int 80h

    ; Write Price
    push esi
    add esi, 48              ; offset to Price field
    call compute_len
    mov eax, 4
    mov ebx, [file_fd]
    mov ecx, esi
    int 80h
    pop esi

    ; Write newline after each record
    mov eax, 4
    mov ebx, [file_fd]
    mov ecx, newline
    mov edx, newline_len
    int 80h

    add esi, 56              ; move to next record
    pop ecx                  ; restore loop counter
    dec ecx
    jnz .save_loop

.close_file:
    ; --- Close the file ---
    mov eax, 6              ; sys_close
    mov ebx, [file_fd]
    int 80h

    ; --- Display exit message ---
    mov eax, 4
    mov ebx, 1
    mov ecx, exit_msg
    mov edx, exit_msg_len
    int 80h

    ; --- Terminate program ---
    mov eax, 1
    xor ebx, ebx
    int 80h

.save_error:
    ; --- Display error message, then exit anyway ---
    mov eax, 4
    mov ebx, 1
    mov ecx, save_err_msg
    mov edx, save_err_msg_len
    int 80h

    mov eax, 1
    xor ebx, ebx
    int 80h