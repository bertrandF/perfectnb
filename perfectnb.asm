; ------------------------------------------------------------------------------
;;    Program to find perfect numbers
;;    Copyright (C) 2014 Bertrand
;;
;;    This program is free software; you can redistribute it and/or modify
;;    it under the terms of the GNU General Public License as published by
;;    the Free Software Foundation; either version 2 of the License, or
;;    (at your option) any later version.
;;
;;    This program is distributed in the hope that it will be useful,
;;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;;    GNU General Public License for more details.
;;
;;    You should have received a copy of the GNU General Public License along
;;    with this program; if not, write to the Free Software Foundation, Inc.,
;;    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; >> https://en.wikipedia.org/wiki/Perfect_number <<
;
; NOTES: With this algorithm I try to find even perfect numbers
; only. I use Euclid theorem on even prefect numbers:
;       N = 2^(p-1) * (2^p - 1) where (2^p - 1) is prime, is perfect.
;
; I use the following algorithm:
;   - Find p, a prime number
;   - Compute N=(2^p-1)
;   - Check that N is prime (Lucas-Lehmer primality test)
;       - IF yes: Found a perfect number 2^(p-1) * (2^p - 1)
;       - IF no : Next loop
;   - Next loop
;
;
; NOTES: To compute a modulo on x86_64:
;   - numerator in      EAX
;   - denominator in    ECX
;   - do                div ECX
;   - remainer in       EDX
;   - WARNING:          EAX is no longer valid !!!
; ------------------------------------------------------------------------------

section .rodata
    printingmsg:    db  "Perfect numbers found:", 10, 0 ; Printing message
    finalizemsg:    db  `Finalizing ...`, 10, 0         ; Finalizing message
    format:         db  "%d", 10, 0                     ; For printf numbers
    limit:          dq  10000                           ; Atkin's sieve limit
    limitsqrt:      dq  100                             ; limit SQRT

section .data
    sieve:          times 50001 db 0                    ; sieve list init to FALSE


section .text
    global  _start
    
    extern  printf
    
    extern  __gmpz_init
    extern  __gmpz_set_ui
    extern  __gmpz_ui_pow_ui
    extern  __gmpz_sub_ui
    extern  __gmpz_mul
    extern  __gmpz_mod
    extern  __gmpz_clear



; ------------------------------------------------------------------------------
; Find the prime numbers using the sieve of Atkin.
; >> http://en.wikipedia.org/wiki/Sieve_of_Atkin <<
;
findprimes:
    ; --- EVERY CALLEE INIT
    push rbp                    ; save caller base pointer
    mov rbp, rsp                ; set new base pointer

    ; -- Known primes
    mov byte [sieve+2], 0xff    ; 2 is prime
    mov byte [sieve+3], 0xff    ; 3 is prime

    ; --- ACTUAL FUNCTION BODY
    ; -- Sieve of Atkin
    ; - main loop
    ; Y = r9 => r11
    ; X = r8 => r10
    mov r8, 1                   ; counter init
.loop_x:
    mov r10, r8     
    imul r10, r10               ; r10 = r8^2
    mov r9, 1                   ; counter init
.loop_y:
    mov r11, r9
    imul r11, r11               ; r11 = r9^2
    mov rax, r10                ; rax = r8^2
    imul rax, 4                 ; rax = 4 * r8^2
    add rax, r11                ; rax = 4*r8^2 + r9^2
    cmp rax, qword [limit]      ; ? rax <= limit
    jg .second_check            ; rax > limit
    xor rcx, rcx
    mov rcx, 12
    xor rdx, rdx                ; need that or raise arithmetic exception
    mov r12, rax
    div rcx                     ; rax = rdx mod(rcx)
    cmp rdx, 1                  ; ? rdx = 1
    je .first_check_valid       ; rdx == 1
    cmp rdx, 5                  ; ? rdx = 5
    jne .second_check           ; rdx != 5
.first_check_valid:
    mov rax, r12
    not BYTE [sieve+rax]        ; Modify sieve
.second_check:
    mov rax, r10                ; rax = r8^2
    imul rax, 3                 ; rax = 3 * r8^2
    add rax, r11                ; rax = 3 * r8^2 + r9^2
    mov r12, rax                ; store this for third_check
    cmp rax, qword [limit]      ; ? rax <= limit
    jg .third_check             ; rax > limit
    xor rcx, rcx
    mov rcx, 12
    xor rdx, rdx                ; need that or raise arithmetic exception
    div rcx                     ; rax = rdx mod(rcx)
    cmp rdx, 7                  ; ? rdx = 7
    jne .third_check            ; rdx != 7
    mov rax, r12
    not BYTE [sieve+rax]        ; Modify sieve
.third_check:
    cmp r8, r9                  ; ? r8 > r9
    jle .loop_y_end             ; r8 <= r9
    sub r12, r11                ; r12 has 3 * r8^2 + r9^2 (from second check)
    sub r12, r11                ; r12 = 3 * r8^2 - r9^2
    cmp r12, qword [limit]      ; ? r12 <= limit
    jg .loop_y_end              ; r12 > limit
    mov rax, r12
    xor rcx, rcx
    mov rcx, 12
    xor rdx, rdx                ; need that or raise arithmetic exception
    div rcx                     ; rax = rdx mod(rcx)
    cmp rdx, 11                 ; ? rdx = 11
    jne .loop_y_end             ; rdx != 11
    mov rax, r12
    not BYTE [sieve+rax]        ; Modify sieve
.loop_y_end:
    inc r9                      ; ++r9
    cmp r9, [limitsqrt]         ; ? r9 <= limit
    jle .loop_y                 ; r9 <= limit -> loop
    inc r8                      ; ++r8
    cmp r8, [limitsqrt]         ; ? r8 <= limit
    jle .loop_x                 ; r8 <= limit -> loop 
    
    ; - finalizing
    xor rax, rax                ; because printf is varargs
    mov rdi, finalizemsg        ; printf 1st arg
    xor rsi, rsi
    call printf
    mov rax, 5                  ; initialize counter
.loop_finalize:
    cmp BYTE [sieve+rax], 0     ; ? nb is prime
    je .loop_finalize_end       ; nb not prime
    mov rbx, rax                
    imul rbx, rbx               ; rbx = nb^2
    mov rcx, rbx                ; init inner counter
.loop_finalize_inner:
    mov BYTE [sieve+rcx], 0     ; nb is prime = false
    add rcx, rbx                ; ++counter
    cmp rcx, [limit]            ; ? rcx <= limit
    jle .loop_finalize_inner    ; rcx <= limit
.loop_finalize_end:
    inc rax                     ; ++counter
    cmp rax, [limitsqrt]        ; ? end of loop
    jle .loop_finalize          ; rax <= limitsqrt

    ; --- EVERY CALLEE CLEAN UP
    mov rsp, rbp                ; desallocate local vars
    pop rbp                     ; restore caller's base pointer
    ret                         ; return
; ------------------------------------------------------------------------------



; ------------------------------------------------------------------------------
; Prints primes from the sieve
;
printprimes:
    ; --- EVERY CALLEE INIT
    push rbp                    ; save caller base pointer
    mov rbp, rsp                ; set new base pointer

    ; - print results
    xor rax, rax                ; because printf is varargs
    mov rdi, printingmsg        ; printf 1st arg
    xor rsi,rsi
    call printf
    mov rcx, 0                  ; init counter
.loop_print:
    inc rcx                     ; ++counter
    cmp byte [sieve+rcx], 0x00  ; ? sieve+rcx == 0
    je .loop_print              ; sieve+rcx = 0
    push rcx                    ; save rcx
    xor rax, rax                ; because printf is varargs
    mov rdi, format             ; printf 1st arg
    xor rsi, rsi
    mov rsi, rcx                ; printf 2nd arg
    call printf                 
    pop rcx                     ; get back saved rcx
    cmp rcx, [limit]            ; ? rcx < limit
    jl .loop_print

    ; --- EVERY CALLEE CLEAN UP
    mov rsp, rbp                ; desallocate local vars
    pop rbp                     ; restore caller's base pointer
    ret                         ; return
; ------------------------------------------------------------------------------



; ------------------------------------------------------------------------------
; Lucas-Lehmer Mersenne prime check.
; >> https://en.wikipedia.org/wiki/Lucas%E2%80%93Lehmer_primality_test <<
;
; lucaslehmer ( p )
; - p : Odd prime number gieven through RAX
; - returns: RAX=0 if FALSE, RAX=1 if true
lucaslehmer:
    ; --- EVERY CALLEE INIT
    push rbp                    ; save caller base pointer
    mov rbp, rsp                ; set new base pointer

    ; --- ACTUAL FUNCTION BODY
    ; Local vars
    ; rbp       => qword p
    ; rbp+10    => qword M
    ; rbp+20    => qword S
    sub rsp, 0x40                 ; Local vars
    mov qword [rsp], rax        ; rbp+8 = p
    
    ; -- Init mpz_t vars
    ;lea rax, [rbp+8]
    ;xor rbx, rbx
    lea rdi, [rsp+0x10]            ; arg1 =>  (mpz_t) M
    call __gmpz_init            ; init M
    lea rdi, [rsp+0x20]           ; arg1 => (mpz_t) S
    call __gmpz_init            ; init S
    lea rdi, [rsp+0x20]           ; arg1 => (mpz_t) S
    mov rsi, 0x04               ; arg2 => init value = 4
    call __gmpz_set_ui          ; S = 0x04
    
    ; -- Compute M = 2^p - 1
    lea rdi, [rsp+0x10]         ; arg1 => result in M
    mov rsi, 0x02               ; arg2 => base = 2
    mov rdx, qword [rsp]        ; arg3 => exp = p
    call __gmpz_ui_pow_ui       ; M = 2^p
    lea rdi, [rsp+0x10]         ; arg1 => result in M
    lea rsi, [rsp+0x10]         ; arg2 => operand1 = M
    mov rdx, 0x01               ; arg3 => operand2 = 0x01
    call __gmpz_sub_ui          ; M = 2^p - 1
    
    ; -- Main loop
    mov rcx, [rsp]              ; rcx will be the counter
    sub rcx, 0x02               ; rcx = p - 2
.loop:
    push rcx                    ; save counter
    ; - process
    lea rdi, [rsp+0x20]         ; arg1 => result in S
    lea rsi, [rsp+0x20]         ; arg2 => operand1 = S
    lea rdx, [rsp+0x20]         ; arg3 => operand2 = S
    call __gmpz_mul             ; S = S * S
    lea rdi, [rsp+0x20]         ; arg1 => result in S
    lea rsi, [rsp+0x20]         ; arg2 => operand1 = S
    mov rdx, 0x02               ; arg3 => operand2 = 0x02
    call __gmpz_sub_ui          ; S = (S*S) - 2
    lea rdi, [rsp+0x20]         ; arg1 => result in S
    lea rdi, [rsp+0x20]         ; arg2 => numerator = S
    lea rdx, [rsp+0x10]         ; arg3 => denominator = M
    call __gmpz_mod             ; S = ((S*S)-2) mod( M )
    ; - check loop end
    pop rcx                     ; restore counter
    dec rcx                     ; counter--
    cmp rcx, 0x00               ; ? counter == 0
    jg .loop                    ; counter > 0

    ; -- Compare S to 0 => S prime ??
    ; TODO: mpz_cmp_ui is a fucking macro !!! find something
    
    ; -- Clean up
    lea rdi, [rsp+8]            ; arg1 =  (mpz_t) M
    call __gmpz_clear           ; clean M
    lea rdi, [rsp+24]           ; arg1 = (mpz_t) M
    call __gmpz_clear           ; clean S

    mov rax, 0x00
    ; --- EVERY CALLEE CLEAN UP
    mov rsp, rbp                ; desallocate local vars
    pop rbp                     ; restore caller's base pointer
    ret                         ; return
; ------------------------------------------------------------------------------



; ------------------------------------------------------------------------------
; Entry point
;
_start:
    ; --- FIND PERFECT NUMBERS
    ; -- FIND prime numbers
    call findprimes
    call printprimes
    
    ; -- LOOP through found primes to find perfect num
    mov rcx, 0x03               ; counter init
.loop:
    cmp byte [sieve+rcx], 0x00  ; ? rcx is prime 
    je .loop_end                ; rcx not prime
    push rcx                    ; save counter
    mov rax, rcx                ; rax = prime number
    call lucaslehmer
    cmp rax, 0x00               ; ? found Mersenne prime
    je .loop_end                ; not Mersenne prime
    xor rax, rax                ; because printf is varargs
    mov rdi, format             ; printf 1st arg
    xor rsi, rsi
    mov rsi, rcx                ; printf 2nd arg
    call printf
.loop_end:
    pop rcx                     ; restore counter
    inc rcx                     ; ++counter
    cmp rcx, [limit]            ; ? rcx > limit 
    jle .loop                   ; rcx <= limit
    
   
    ; --- EXIT
    mov rax, 60                 ; sys_exit
    mov rdi, 0                  ; EXIT_SUCCESS
    syscall
; ------------------------------------------------------------------------------
    
