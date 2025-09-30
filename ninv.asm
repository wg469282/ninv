; ============================================================================
; Function: ninv
;
; Calculates integer inverse y = floor(2^n / x) for large numbers.
;
; Arguments:
;   rdi: uint64_t *Y   - pointer to array for result (quotient)
;   rsi: uint64_t *X   - pointer to array with divisor
;   edx: unsigned n    - number of bits (power of two in dividend)
;
; Version: 1.2 - Version with comprehensive documentation
; ============================================================================


default rel
global ninv: function


SECTION .text align=16 exec


ninv:
        ; --------------------------------------------------------------------
        ; Function prolog: preserving caller's state
        ; --------------------------------------------------------------------
        push    rbp                             ; Save old stack base pointer
        mov     rbp, rsp                        ; Set new stack frame pointer for this function
        push    r15                             ; Save callee-saved register r15
        push    r14                             ; Save callee-saved register r14
        push    r13                             ; Save callee-saved register r13
        push    r12                             ; Save callee-saved register r12
        push    rbx                             ; Save callee-saved register rbx


        ; --------------------------------------------------------------------
        ; Initialization: preparing registers and parameters
        ; --------------------------------------------------------------------
        mov     r11, rsi                        ; r11 holds pointer to divisor (X)
        mov     r10, rdi                        ; r10 holds pointer to result (Y)
        mov     r8d, edx                        ; r8d holds original value of n (number of bits)
        shr     edx, 6                          ; edx = n / 64, calculate X length in 64-bit words
        mov     esi, edx                        ; esi holds this length (denoted as 'w')


        ; --------------------------------------------------------------------
        ; Allocation and zeroing of working buffers on stack
        ; --------------------------------------------------------------------
        lea     rcx, [rsi+1]                    ; Calculate remainder buffer size: w+1 words
        mov     rbx, rcx                        ; Keep this size in rbx for use by `rep stosq`
        shl     rcx, 3                          ; Convert buffer size from words to bytes (size * 8)
        
        sub     rsp, rcx                        ; Reserve memory for remainder buffer on stack
        and     rsp, -16                        ; Align stack pointer to 16-byte boundary (ABI requirement)
        mov     r13, rsp                        ; r13 will be constant pointer to remainder buffer


        xor     eax, eax                        ; Zero EAX register (value to store: 0)
        mov     rdi, r13                        ; Set RDI to target address (remainder buffer)
        mov     rcx, rbx                        ; Set counter for words to zero
        rep     stosq                           ; Fill entire remainder buffer with zeros (equivalent to memset)


        mov     rdi, r10                        ; Set RDI to target address (result buffer)
        mov     ecx, esi                        ; Set counter for words (length 'w')
        rep     stosq                           ; Fill entire result buffer with zeros


; ----------------------------------------------------------------------------
; "Bit by bit" division algorithm
; ----------------------------------------------------------------------------


find_x_length:
        ; Determine actual length of divisor X (skip leading zeros)
        test    esi, esi                        ; Check if length 'w' (esi) is zero
        je      cleanup_and_return              ; If so, exit (division by zero or empty data)
        lea     rcx, [rsi-1]                    ; Calculate index of last word (w - 1)
        cmp     qword [r11+rcx*8], 0            ; Compare last word of X with zero
        jnz     init_remainder                  ; If non-zero, this is the most significant word, continue
        dec     esi                             ; If zero, decrease effective length 'w'
        jmp     find_x_length                   ; And check next word


init_remainder:
        ; Initialize remainder (R) to 1 before starting main loop
        mov     ecx, r8d                        ; Restore original value of n to ECX
        dec     ecx                             ; Main loop counter will iterate from n-1 to 0
        mov     eax, 1                          ; Set remainder length in words to 1
        mov     qword [r13], 1                  ; Set remainder value R = 1 (as single word)
        mov     r12d, 1                         ; Load constant '1' into r12d, will be used for setting bits


main_division_loop:
        test    ecx, ecx                        ; Check if bit counter (n-1) dropped below zero
        js      cleanup_and_return              ; If so, finish algorithm


        ; Shift remainder R left by 1 bit (R = R * 2)
        xor     edi, edi                        ; Zero word index (i=0) in shift loop
        xor     r9, r9                          ; Zero register r9, will hold carry bit
shift_loop:
        cmp     edi, eax                        ; Check if all remainder words processed
        jnc     check_carry_extend              ; If so, exit shift loop
        
        mov     r14, qword [r13+rdi*8]          ; Load i-th word of remainder
        lea     r15, [r14+r14]                  ; Shift it left by 1
        shr     r14, 63                         ; Isolate highest bit (MSB), becomes new carry
        or      r9, r15                         ; Combine shifted word with carry from previous iteration
        mov     qword [r13+rdi*8], r9           ; Store new remainder word
        
        inc     edi                             ; Move to next word
        mov     r9, r14                         ; Save new carry for next iteration
        jmp     shift_loop                      ; Continue shift loop


check_carry_extend:
        ; If carry occurred from most significant word, extend remainder
        test    r9, r9                          ; Check if last carry was non-zero
        jz      compare_remainder_x             ; If not, proceed to comparison
        cmp     eax, ebx                        ; Check if there's space in remainder buffer
        jnc     compare_remainder_x             ; If buffer full, skip extension
        mov     qword [r13+rax*8], 1            ; Add new word (value 1) at end of remainder
        inc     eax                             ; Increase remainder length in words


compare_remainder_x:
        ; Compare remainder R with divisor X (if R >= X)
        cmp     esi, eax                        ; Compare length of X (w) with length of R
        jc      set_bit_and_subtract            ; If R is longer, it's definitely greater
        jne     next_bit                        ; If X is longer, it's definitely greater
        
        ; If lengths are equal, compare word by word from most significant
        mov     edi, esi                        ; Set comparison loop counter to 'w'
word_compare_loop:
        dec     rdi                             ; Decrement index (from w-1 to 0)
        mov     r8, qword [r13+rdi*8]           ; Load remainder word
        cmp     r8, qword [r11+rdi*8]           ; Compare with word from X
        jb      next_bit                        ; If R_i < X_i, then whole number R < X, go to next bit
        ja      set_bit_and_subtract            ; If R_i > X_i, then whole number R > X, set bit and subtract
        test    rdi, rdi                        ; Check if this was last word (index 0)
        jnz     word_compare_loop               ; If not, continue comparing next words
        ; If all words are equal, then R >= X, so also set bit and subtract


set_bit_and_subtract:
        ; Set corresponding bit in result Y
        mov     edi, ecx                        ; Use loop counter (n-1..0) as bit position
        mov     r8, r12                         ; r8 = 1 (bit value to set)
        sar     edi, 6                          ; edi = word index in Y (position / 64)
        shl     r8, cl                          ; r8 = bit mask (1 << (position % 64))
        movsxd  rdi, edi                        ; Extend 32-bit index to 64 bits for correct addressing
        or      qword [r10+rdi*8], r8           ; Set bit: Y[index] |= mask
        
        ; Step 3b: Subtraction (R = R - X) with manual borrow handling
        xor     r9, r9                          ; Zero register r9, will hold borrow bit
        xor     r8d, r8d                        ; Zero word index (i=0) in subtraction loop
subtract_loop:
        cmp     r8d, eax                        ; Check if all remainder words processed
        jnc     reduce_remainder_length         ; If so, exit subtraction loop
        
        xor     edi, edi                        ; Default word from X to subtract is 0
        cmp     r8d, esi                        ; Check if index 'i' is within X length range
        jnc     get_x_word_zero                 ; If not, use default zero (X is shorter than R)
        mov     rdi, qword [r11+r8*8]           ; If so, load i-th word from X
get_x_word_zero:
        mov     r14, qword [r13+r8*8]           ; Load old value of i-th remainder word
        mov     r15, r14                        ; Copy it to working register
        sub     r15, r9                         ; Subtract borrow from previous iteration
        sub     r15, rdi                        ; Subtract word from X
        mov     qword [r13+r8*8], r15           ; Store result in remainder


        ; Manual calculation of new borrow
        add     rdi, r9                         ; rdi = X[i] + input_borrow
        jc      new_borrow_found                ; If (X[i] + borrow_in) > MAX_UINT, borrow needed
        cmp     r14, rdi                        ; Compare original remainder R[i] with (X[i] + borrow_in)
        jc      new_borrow_found                ; If R[i] was smaller, borrow needed
        xor     r9, r9                          ; Otherwise, new borrow = 0
        jmp     no_new_borrow
new_borrow_found:
        mov     r9, 1                           ; Set new borrow to 1
no_new_borrow:
        inc     r8d                             ; Move to next word
        jmp     subtract_loop                   ; Continue subtraction loop


reduce_remainder_length:
        ; Normalize remainder R: remove leading zeros after subtraction
reduce_loop:
        cmp     eax, 1                          ; Check if remainder length is greater than 1
        jle     next_bit                        ; If not, finish (always keep at least 1 word)
        lea     rdi, [rax-1]                    ; Calculate index of last remainder word
        cmp     qword [r13+rdi*8], 0            ; Check if this word is zero
        jnz     next_bit                        ; If not, finish reduction
        dec     eax                             ; If it's zero, decrease remainder length
        jmp     reduce_loop                     ; And check next word


next_bit:
        ; Move to next iteration (next bit)
        dec     ecx                             ; Decrease main bit counter
        jmp     main_division_loop              ; Return to beginning of loop


; ----------------------------------------------------------------------------
; Function epilog: restore state and return
; ----------------------------------------------------------------------------
cleanup_and_return:
        lea     rsp, [rbp-40]                   ; Free memory allocated on stack
        pop     rbx                             ; Restore callee-saved register rbx
        pop     r12                             ; Restore callee-saved register r12
        pop     r13                             ; Restore callee-saved register r13
        pop     r14                             ; Restore callee-saved register r14
        pop     r15                             ; Restore callee-saved register r15
        pop     rbp                             ; Restore old stack frame pointer
        ret                                     ; Return from function
