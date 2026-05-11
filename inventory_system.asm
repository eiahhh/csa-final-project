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
        
    ;---Display Inventory
        disp_header         db 0Ah, "========================================", 0Ah
                            db "     CURRENT INVENTORY", 0Ah
                            db "========================================", 0Ah
        disp_header_len     equ $ - disp_header
        disp_col_header     db "ID        NAME                    QTY      PRICE   ", 0Ah
                            db "-------------------------------------------------", 0Ah
        disp_col_len        equ $ - disp_col_header
        disp_sep            db "-------------------------------------------------", 0Ah
        disp_sep_len        equ $ - disp_sep
        disp_empty_msg       db 0Ah, "[INFO] Inventory is empty.", 0Ah
        disp_empty_len      equ $ - disp_empty_msg
        disp_total_label    db "Total Items: "
        disp_total_len      equ $ - disp_total_label
        
        ;---Column Padding
        pad_spaces          db "                                "
        pad_spaces_len      equ $ - pad_spaces

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
        rep_name_lbl db "  Name     : "
        rep_name_lbl_len equ $ - rep_name_lbl
        rep_qty_lbl db "  Quantity : "
        rep_qty_lbl_len equ $ - rep_qty_lbl
        rep_footer db "-------------------------------------------------", 0Ah, "End of Report", 0Ah
        rep_footer_len equ $ - rep_footer
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

        num_buffer  resb 16 ; for report calculations
        num_buf     resb 12 ; for print_uint32

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
        
    ;---Display Inventory
    display_inventory:
        ; print section header
        mov eax, 4
        mov ebx, 1
        mov ecx, disp_header
        mov edx, disp_header_len
        int 80h
    
        ; check if inventory is empty
        mov eax, [item_count]
        cmp eax, 0
        je disp_empty
    
        ; print column header
        mov eax, 4
        mov ebx, 1
        mov ecx, disp_col_header
        mov edx, disp_col_len
        int 80h
    
        ; loop: ESI = first record, ECX = item count
        mov esi, inventory
        mov ecx, [item_count]
    
    disp_row_loop:
        push ecx
    
        ; --- ID: print value then pad to width 10 ---
        mov ecx, 10             ; column width for ID
        call print_padded_8     ; prints [ESI+0..7] then spaces to fill col width
    
        ; --- Name
        add esi, 8
        mov ecx, 24             ; column width for Name
        call print_padded_32    
        sub esi, 8
    
        ; --- Quantity
        add esi, 40
        mov ecx, 9              ; column width for Qty
        call print_padded_8
        sub esi, 40
    
        ; --- Price
        add esi, 48
        call compute_len
        mov eax, 4
        mov ebx, 1
        mov ecx, esi
        int 80h
        sub esi, 48
        
        mov eax, 4
        mov ebx, 1
        mov ecx, newline
        mov edx, newline_len
        int 80h
    
        add esi, 56             ; advance to next record
        pop ecx
        dec ecx
        jnz disp_row_loop
    
        ;---Footer: separator + total count
        mov eax, 4
        mov ebx, 1
        mov ecx, disp_sep
        mov edx, disp_sep_len
        int 80h
        
        mov eax, 4
        mov ebx, 1
        mov ecx, disp_total_label
        mov edx, disp_total_len
        int 80h
    
        mov eax, [item_count]
        call print_uint32
    
        mov eax, 4
        mov ebx, 1
        mov ecx, newline
        mov edx, newline_len
        int 80h
    
        jmp main_menu
        
    disp_empty:
        mov eax, 4
        mov ebx, 1
        mov ecx, disp_empty_msg
        mov edx, disp_empty_len
        int 80h
        jmp main_menu

    ;---Subroutines
    print_field_8:
        push eax
        push ebx
        push ecx
        push edx
        push esi
        push edi
    
        mov edi, esi
        mov ecx, 8
    .pf8_scan:
        cmp byte [edi], 0Ah
        je  .pf8_emit
        cmp byte [edi], 0
        je  .pf8_emit
        inc edi
        dec ecx
        jnz .pf8_scan
    .pf8_emit:
        mov edx, edi
        sub edx, esi            ; length in bytes
        cmp edx, 0
        je  .pf8_nl
        mov eax, 4
        mov ebx, 1
        mov ecx, esi
        int 80h
    .pf8_nl:
        mov eax, 4
        mov ebx, 1
        mov ecx, newline
        mov edx, 1
        int 80h
    
        pop edi
        pop esi
        pop edx
        pop ecx
        pop ebx
        pop eax
        ret
    
    print_field_32:
        push eax
        push ebx
        push ecx
        push edx
        push esi
        push edi
    
        mov edi, esi
        mov ecx, 32
    .pf32_scan:
        cmp byte [edi], 0Ah
        je  .pf32_emit
        cmp byte [edi], 0
        je  .pf32_emit
        inc edi
        dec ecx
        jnz .pf32_scan
    .pf32_emit:
        mov edx, edi
        sub edx, esi
        cmp edx, 0
        je  .pf32_nl
        mov eax, 4
        mov ebx, 1
        mov ecx, esi
        int 80h
    .pf32_nl:
        mov eax, 4
        mov ebx, 1
        mov ecx, newline
        mov edx, 1
        int 80h
    
        pop edi
        pop esi
        pop edx
        pop ecx
        pop ebx
        pop eax
        ret
    
    print_inline_8:
        push eax
        push ecx
        push edx
        push esi
        push edi
    
        mov edi, esi
        mov ecx, 8
    .pi8_scan:
        cmp byte [edi], 0Ah
        je  .pi8_emit
        cmp byte [edi], 0
        je  .pi8_emit
        inc edi
        dec ecx
        jnz .pi8_scan
    .pi8_emit:
        mov edx, edi
        sub edx, esi            ; printed length
        push edx                ; save length for caller (returned in EBX below)
        cmp edx, 0
        je  .pi8_done
        mov eax, 4
        mov ebx, 1
        mov ecx, esi
        int 80h
    .pi8_done:
        pop ebx                 ; EBX = number of bytes printed
    
        pop edi
        pop esi
        pop edx
        pop ecx
        pop eax
        ret
    
    print_inline_32:
        push eax
        push ecx
        push edx
        push esi
        push edi
    
        mov edi, esi
        mov ecx, 32
    .pi32_scan:
        cmp byte [edi], 0Ah
        je  .pi32_emit
        cmp byte [edi], 0
        je  .pi32_emit
        inc edi
        dec ecx
        jnz .pi32_scan
    .pi32_emit:
        mov edx, edi
        sub edx, esi
        push edx
        cmp edx, 0
        je  .pi32_done
        mov eax, 4
        mov ebx, 1
        mov ecx, esi
        int 80h
    .pi32_done:
        pop ebx                 ; EBX = bytes printed
    
        pop edi
        pop esi
        pop edx
        pop ecx
        pop eax
        ret
    
    print_padded_8:
        push eax
        push ecx
        push edx
        push esi
        push edi
    
        mov edx, ecx            ; save column width in EDX
    
        call print_inline_8     ; prints field; EBX = chars printed
    
        ; pad = column_width - printed_len
        mov ecx, edx
        sub ecx, ebx            ; ECX = number of spaces needed
        cmp ecx, 0
        jle .pp8_done
    
        ; Write ECX spaces from pad_spaces
        cmp ecx, 32
        jle .pp8_write
        mov ecx, 32             ; clamp to buffer size
    .pp8_write:
        mov eax, 4
        mov ebx, 1
        mov edx, ecx
        mov ecx, pad_spaces
        int 80h
    
    .pp8_done:
        pop edi
        pop esi
        pop edx
        pop ecx
        pop eax
        ret
    
    print_padded_32:
        push eax
        push ecx
        push edx
        push esi
        push edi
    
        mov edx, ecx            ; save column width
    
        call print_inline_32    ; prints field; EBX = chars printed
    
        mov ecx, edx
        sub ecx, ebx            ; spaces needed
        cmp ecx, 0
        jle .pp32_done
    
        cmp ecx, 32
        jle .pp32_write
        mov ecx, 32
    .pp32_write:
        mov eax, 4
        mov ebx, 1
        mov edx, ecx
        mov ecx, pad_spaces
        int 80h
    
    .pp32_done:
        pop edi
        pop esi
        pop edx
        pop ecx
        pop eax
        ret
    
    ascii_to_int:
        xor eax, eax
    .a2i_loop:
        movzx ebx, byte [edi]
        cmp bl, '0'
        jl  .a2i_done
        cmp bl, '9'
        jg  .a2i_done
        sub bl, '0'
        imul eax, eax, 10
        add eax, ebx
        inc edi
        jmp .a2i_loop
    .a2i_done:
        ret
    
    print_uint32:
        mov edi, num_buffer + 11   ; work right-to-left in buffer
        xor ecx, ecx               ; digit counter
    
        cmp eax, 0
        jne .pu32_cvt
    
        ; Special case: value is 0
        dec edi
        mov byte [edi], '0'
        inc ecx
        jmp .pu32_print
    
    .pu32_cvt:
        mov ebx, 10
    .pu32_loop:
        cmp eax, 0
        je  .pu32_print
        xor edx, edx
        div ebx                 ; EAX = quotient, EDX = remainder
        add dl, '0'
        dec edi
        mov [edi], dl
        inc ecx
        jmp .pu32_loop
    
    .pu32_print:
        ; EDI = first digit, ECX = digit count
        mov edx, ecx
        mov ecx, edi
        mov eax, 4
        mov ebx, 1
        int 80h
        ret

    ;---Generate Report
    generate_report:
        mov eax, [item_count]
        test eax, eax
        jnz .rpt_has_items

        ; Empty inventory case
        mov eax, 4
        mov ebx, 1
        mov ecx, report_header
        mov edx, report_header_len
        int 80h

        ; Print total stock value
        mov eax, 4
        mov ebx, 1
        mov ecx, total_value_msg
        mov edx, total_value_msg_len
        int 80h

        mov eax, 0
        call itoa
        mov ecx, edi
        mov edx, num_buffer + 16
        sub edx, ecx
        mov eax, 4
        mov ebx, 1
        int 80h

        mov eax, 4
        mov ebx, 1
        mov ecx, newline
        mov edx, newline_len
        int 80h

        ; Print low stock message
        mov eax, 4
        mov ebx, 1
        mov ecx, low_stock_msg
        mov edx, low_stock_msg_len
        int 80h

        mov eax, 4
        mov ebx, 1
        mov ecx, no_low_stock
        mov edx, no_low_stock_len
        int 80h
        
        mov eax, 4
        mov ebx, 1
        mov ecx, newline
        mov edx, newline_len
        int 80h

        mov eax, 4
        mov ebx, 1
        mov ecx, rep_footer
        mov edx, rep_footer_len
        int 80h

        jmp main_menu

    .rpt_has_items:
        ; Initialize accumulators
        xor edi, edi                ; EDI = total stock value
        xor ebp, ebp                ; EBP = low-stock item count
        mov ecx, [item_count]       ; ECX = loop counter
        mov esi, inventory          ; ESI = current record pointer

    .rpt_pass1_loop:
        push ecx                    ; save loop counter
        
        ; Read quantity from offset 40
        mov edx, esi                ; EDX = base address (save it)
        add edx, 40                 ; EDX now points to quantity field
        mov esi, edx                ; Set ESI to quantity field address
        call atoi                   ; EAX = quantity
        mov ebx, eax                ; EBX = quantity
        
        ; Read price from offset 48 (relative to base)
        mov esi, edx                ; ESI = quantity field address (edx + 40)
        sub esi, 40                 ; ESI = base address
        add esi, 48                 ; ESI = price field address
        push ebx                    ; save quantity
        call atoi                   ; EAX = price
        pop ebx                     ; restore quantity
        
        ; Calculate value and add to total
        imul eax, ebx               ; EAX = price * qty
        add edi, eax                ; total += value
        
        ; Check low stock
        cmp ebx, LOW_STOCK_THRESHOLD
        jge .pass1_skip_low
        inc ebp                     ; increment low-stock count
        
    .pass1_skip_low:
        mov esi, edx
        sub esi, 40                 ; restore ESI to base address
        add esi, 56                 ; Move to next record
        pop ecx                     ; restore loop counter
        dec ecx                     ; Decrement loop counter
        jnz .rpt_pass1_loop

        ; Pass 1 complete. EBP = low stock count, EDI = total stock value.
        ; Print report header
        mov eax, 4
        mov ebx, 1
        mov ecx, report_header
        mov edx, report_header_len
        int 80h

        ; Print total stock value
        mov eax, 4
        mov ebx, 1
        mov ecx, total_value_msg
        mov edx, total_value_msg_len
        int 80h

        mov eax, edi
        call itoa
        mov ecx, edi
        mov edx, num_buffer + 16
        sub edx, ecx
        mov eax, 4
        mov ebx, 1
        int 80h

        mov eax, 4
        mov ebx, 1
        mov ecx, newline
        mov edx, newline_len
        int 80h

        ; Print low-stock message
        mov eax, 4
        mov ebx, 1
        mov ecx, low_stock_msg
        mov edx, low_stock_msg_len
        int 80h

        cmp ebp, 0
        jne .rpt_pass2_setup

        ; No low stock items
        mov eax, 4
        mov ebx, 1
        mov ecx, no_low_stock
        mov edx, no_low_stock_len
        int 80h

        mov eax, 4
        mov ebx, 1
        mov ecx, newline
        mov edx, newline_len
        int 80h

        mov eax, 4
        mov ebx, 1
        mov ecx, rep_footer
        mov edx, rep_footer_len
        int 80h

        jmp main_menu

    .rpt_pass2_setup:
        mov ecx, [item_count]       ; ECX = loop counter
        mov esi, inventory          ; ESI = current record pointer

    .rpt_pass2_loop:
        push ecx                    ; save loop counter
        
        ; Read quantity from offset 40
        mov edx, esi                ; EDX = base address (save it)
        add edx, 40                 ; EDX now points to quantity field
        mov esi, edx                ; Set ESI to quantity field address
        call atoi                   ; EAX = quantity
        mov ebx, eax                ; EBX = quantity
        
        ; ESI was modified by atoi, restore it to base for low-stock check
        mov esi, edx
        sub esi, 40                 ; ESI = base address
        
        ; Check low stock
        cmp ebx, LOW_STOCK_THRESHOLD
        jge .pass2_skip_low
        
        ; Print low-stock item
        mov eax, 4
        mov ebx, 1
        mov ecx, low_stock_item
        mov edx, low_stock_item_len
        int 80h
        
        ; Print ID
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
        
        ; Print Name label
        mov eax, 4
        mov ebx, 1
        mov ecx, rep_name_lbl
        mov edx, rep_name_lbl_len
        int 80h
        
        ; Print Name
        push esi
        add esi, 8
        call compute_len
        mov eax, 4
        mov ebx, 1
        mov ecx, esi
        int 80h
        pop esi
        
        ; Print newline
        mov eax, 4
        mov ebx, 1
        mov ecx, newline
        mov edx, newline_len
        int 80h
        
        ; Print Qty label
        mov eax, 4
        mov ebx, 1
        mov ecx, rep_qty_lbl
        mov edx, rep_qty_lbl_len
        int 80h
        
        ; Print Qty
        push esi
        add esi, 40
        call compute_len
        mov eax, 4
        mov ebx, 1
        mov ecx, esi
        int 80h
        pop esi
        
        ; Print newline (twice)
        mov eax, 4
        mov ebx, 1
        mov ecx, newline
        mov edx, newline_len
        int 80h
        mov eax, 4
        mov ebx, 1
        mov ecx, newline
        mov edx, newline_len
        int 80h
        
    .pass2_skip_low:
        ; Move to next record
        add esi, 56
        pop ecx                     ; restore loop counter
        dec ecx                     ; Decrement loop counter
        jnz .rpt_pass2_loop
        
        mov eax, 4
        mov ebx, 1
        mov ecx, rep_footer
        mov edx, rep_footer_len
        int 80h

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
