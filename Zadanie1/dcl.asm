global _start

MAXASCII_1 equ 91
MAXASCII   equ 90
MINASCII_1 equ 48
MINASCII   equ 49
LASCII     equ 76
RASCII     equ 82
TASCII     equ 84
PLENGTH    equ 42
SYS_EXIT   equ 60
SYS_WRITE  equ 1
STDOUT     equ 1
LRLENGTH   equ 2
; Reserve bytes for our variables
section .bss
        buffer:        resb 4096
        left:          resb 64
        leftReversed:  resb 64
        right:         resb 64
        rightReversed: resb 64
        t:             resb 64
        state:         resb 2

section .text

increaseOne:
        mov     r13b, [r15+1]          ; Move r position to r13b
        inc     r13b                   ; Increase r position
        cmp     r13b, MAXASCII_1       ; Check if we moved out of allowed range for char
        jnz     .changeR               ; If not jump
        mov     r13b, MINASCII         ; If yes assign to r13b char = '1'
.changeR:
        mov     [r15+1], r13b          ; Change value of r position to the new one
        cmp     r13b, LASCII           ; Check if r position equals 'L'
        jz      .increaseL             ; If yes change l position
        cmp     r13b, RASCII           ; Check if r position equals 'R'
        jz      .increaseL             ; If yes change l position
        cmp     r13b, TASCII           ; Check if r position equals 'T'
        jz      .increaseL             ; If yes change l position
        jmp     .return                ; If no end of function

.increaseL:
        mov     r13b, [r15]            ; Move l position to r13b
        inc     r13b                   ; Increase l position
        cmp     r13b, MAXASCII_1       ; Check if we moved out of allowed range for char
        jnz     .changeL               ; If no jump
        mov     r13b, MINASCII         ; If yes assign to r13b = '1'
.changeL:
        mov     [r15], r13b            ; Change value of l position to the new one
.return:
        ret


checkCycles:
        xor     ecx, ecx               ; Set index of T to 0
.nextCharCycle:
        mov     r13b, [rax+rcx]        ; Move rcx-th element of T to r13b
        mov     r14b, [rax+r13-MINASCII] ; Move r13b-th element of T to r14b
        mov     r15b, [rax+r14-MINASCII] ; Move r14-th element of T to r15b
        cmp     r13b, 0                ; Check if end of T
        jz      .finished2             ; If yes then end of function
        cmp     r13b, r15b             ; Check if after 2 jumps through T we came back to original char
                                       ; i.e we have 2-element cycle
        jnz     error                  ; If not exit program with 1
        inc     rcx                    ; Increase T index
        jmp     .nextCharCycle         ; Check next char
.finished2:
        ret

checkValidity:
        xor     ecx, ecx               ; Set index of L/R/T/State(argument) to 0(for first loop)
.nextChar:
        mov     r13b, [rax+rcx]        ; Move rcx-th element of argument to r13b
        cmp     r13b, 0                ; Check if end of argument
        jz      .finished              ; Conditional jump - end of function
        cmp     r13b, MINASCII         ; Check if forbidden char(< 49)
        jl      error                  ; If yes exit program with 1 code
        cmp     r13b, MAXASCII         ; Check if forbidden char(> 90)
        jg      error                  ; If yes exit program with 1 code
        inc     rcx                    ; Increase argument index
        mov     rbx, rcx               ; Set rbx to present argument index(for 2nd loop)
        cmp     r9, LRLENGTH           ; Check if we validate last argument
        jz      .nextChar              ; In such case we omit checking for repeated chars
.searchRepeated:
        mov     r14b, [rax+rbx]        ; Move rbx-th element of argument to r14b
        cmp     r14b, 0                ; Check if end of argument
        jz      .nextChar              ; If yes jump to checking next char of argument(1st loop)
        cmp     r13b, r14b             ; Check for repeated char
        jz      error                  ; If yes exit program with 1 code
        inc     rbx                    ; Increase argument index
        jmp     .searchRepeated        ; Check next char(2st loop)
.finished:
        ret

error:
        mov     rax, SYS_EXIT          ; Set rax to sys_exit opcode
        mov     rdi, 1                 ; Set rdi to code 1
        syscall                        ; Exit program with 1 code - failed program
        ret


input:
.inputLoop:
        xor     eax, eax               ; Set rax to sys_read opcode
        xor     edi, edi               ; Read from stdin
        mov     rsi, buffer            ; Read to buffer
        mov     rdx, 4096              ; Read 4096 bytes(the size of buffer)
        syscall

        ret

computeReversed:
        xor     ecx, ecx               ; Set L/R index to 0
        add     rcx, MINASCII          ; Set L/R index to 49 - to let us assign the corresponding char instantly
.computeLoop:
        mov     r11b, [r15+rcx-MINASCII] ; Move i-th L/R character to r11b
        mov     [rbx+r11-MINASCII], cl   ; On i-th position in L-1 place i+49-th char i.e compute part of L-1
        inc     cl                     ; Increase L/R index
        cmp     cl, MAXASCII_1         ; Check if end of L/R
        jne     .computeLoop           ; If not process next char

        ret

qPermutation:
        sub     r11b, 53               ; Set our current character we are encrypting to char-53
                                       ; We subtract 53 instead of 49 to avoid overflowing r11b
        add     r11b, r12b             ; Add l/r position to current char
        cmp     r11b, 87               ; Check if current char is in allowed range
                                       ; We compare with 87 instead of 91 because we subtracted 53
        jl      .valueChanged          ; If yes end of function
        sub     r11b, PLENGTH
        cmp     r11b, 87               ; Check if current char is in allowed range
        jl      .valueChanged          ; If yes end of function
        sub     r11b, PLENGTH          ; Now it has to be in allowed range
.valueChanged:
        add     r11b, 4                ; We add 4 to equal the 53 subtraction
        ret

q1Permutation:
        sub     r11b, r12b             ; Subtract l/r position from current char
        add     r11b, MINASCII         ; Add the ascii value of 1
        cmp     r11b, MINASCII_1       ; Check if current char is in allowed range
        jg      .valueChanged2         ; If yes end of function
        add     r11b, PLENGTH
        cmp     r11b, MINASCII_1
        jg      .valueChanged2
        add     r11b, PLENGTH          ; Now it has to be in allowed range
.valueChanged2:
        ret

;Main
_start:

.argsParsing:
        pop     rcx                    ; Move number of arguments to rcx
        pop     rbx                    ; Move address of program name to rbx
        pop     rbx                    ; Move address of first argument - L permutation to rbx
        mov     [left], rbx            ; Move address of L to left variable
        pop     rbx                    ; Move address of second argument - R permutation to rbx
        mov     [right], rbx           ; Move address of R to right variable
        pop     rbx                    ; Move address of third argument - T permutation to rbx
        mov     [t], rbx               ; Move address of T to t variable
        pop     rbx                    ; Move address of forth argument - lr positions to rbx
        mov     [state], rbx           ; Move address of lr positions to rbx
        mov     rax, [left]            ; Move address of L to rax
        call    checkValidity          ; Check validity of L
        cmp     rcx, PLENGTH           ; Check if length of L is right
        jnz     error                  ; If not exit program with 1
        mov     rax, [right]           ; Move address of R to rax
        call    checkValidity          ; Check validity of R
        cmp     rcx, PLENGTH           ; Check if length of R is right
        jnz     error                  ; If not exit program with 1
        mov     rax, [t]               ; Move address of T to rax
        call    checkValidity          ; Check validity of T
        call    checkCycles            ; Check if T contains 21 2-element cycles
        cmp     rcx, PLENGTH           ; Check if length of T is right
        jnz     error                  ; If not exit program with 1
        mov     r9, LRLENGTH           ; Set r9 to flag telling in this case checkValidity has to omit checking for repeated chars
        mov     rax, [state]           ; Move address of lr positions to rax
        call    checkValidity          ; Check validity of lr positions
        cmp     rcx, LRLENGTH          ; Check if length of state is right
        jnz     error                  ; If not exit program with 1

        mov     r15, [left]            ; Move address of L to r15
        mov     rbx, leftReversed      ; Move address of L-1 to rbx
        call    computeReversed        ; Compute reversed L i.e L-1

        mov     r15, [right]           ; Move address of R to r15
        mov     rbx, rightReversed     ; Move address of R-1 to rbx
        call    computeReversed        ; Compute reversed R i.e R-1
.permutateText:
        call    input                  ; Load part of user's input to buffer
        xor     ecx, ecx               ; Set loop index to 0
        mov     rbx, rax               ; Move number of read bytes from stdin to rbx
        cmp     rax, 0                 ; Check if 0 bytes were read i.e input has ended
        jz      .exit                  ; If yes exit program with 0
 .textLoop:
        cmp     rcx, rbx               ; Check if we processed all chars from input
        jz      .print                 ; If yes then print encrypted buffer
        mov     r15, [state]           ; Move address of lr positions to r15
        call    increaseOne            ; Before processing char increase lr positions
        mov     r11b, [buffer+rcx]     ; Load i-th element of input to r11b
        cmp     r11b, MINASCII         ; Check if forbidden char(< 49)
        jl      error                  ; If yes exit program with 1
        cmp     r11b, MAXASCII         ; Check if forbidden char(> 49)
        jg      error                  ; If yes exit program with 1
        mov     r12b, [r15+1]          ; Move r position to r12b
        call    qPermutation           ; Perform q(r) permutation
        mov     r10b, r11b             ; Move current char to r10b
        mov     r12, [right]           ; Move R to r12
        mov     r11b, [r12 + r10 - MINASCII] ; Change current character according to R permutation
        mov     r12b, [r15+1]          ; Now we repeat the same actions to perform the sequence of permutations from task
        call    q1Permutation
        mov     r12b, [r15]
        call    qPermutation
        mov     r10b, r11b
        mov     r12, [left]
        mov     r11b, [r12 + r10 - MINASCII]
        mov     r12b, [r15]
        call    q1Permutation
        mov     r10b, r11b
        mov     r12, [t]
        mov     r11b, [r12 + r10 - MINASCII]
        mov     r12b, [r15]
        call    qPermutation
        mov     r10b, r11b
        mov     r12, leftReversed
        mov     r11b, [r12 + r10 - MINASCII]
        mov     r12b, [r15]
        call    q1Permutation
        mov     r12b, [r15+1]
        call    qPermutation
        mov     r10b, r11b
        mov     r12, rightReversed
        mov     r11b, [r12 + r10 - MINASCII]
        mov     r12b, [r15+1]
        call    q1Permutation
        mov     [buffer+rcx], r11b     ; We got our encrypted character, so we move into corresponding position in buffer
        inc     rcx                    ; Increase loop index
        jmp     .textLoop              ; Encrypt next character

 .print:
        mov     rdx, rbx               ; Move number of bytes to write to rdx
        mov     rsi, buffer            ; Move the address of text to write
        mov     rdi, STDOUT            ; Write to stdout
        mov     rax, SYS_WRITE         ; Opcode of sys_write
        syscall
        jmp     .permutateText
.exit:
        mov     rax, SYS_EXIT          ; Opcode of sys_exit
        xor     edi, edi               ; Set exit code to 0
        syscall
