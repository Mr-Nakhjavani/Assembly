global asm_main
extern printf 
extern gets
extern strlen
extern atoi
section .text

; SystemV AMD64 ABI 
; Integer Function arguments : RDI, RSI, RDX, RCX, R8, R9, (Extra on stack)
; Float/Double Function arguments : [XYZ]MM[0-7]
; Return value : RAX
; More Info : https://wiki.osdev.org/System_V_ABI#x86-64

asm_main:
 sub rsp, 40          ; Align stack to 16-byte boundary (make space for local variables)
 ; we are working with c => rsp % 16 = 0 before any function call
 ; when asm_main is called, return address is pushed on stack
    ; so rsp%16 = 8 => we need to fix this by rsp-=8
 mov rdi, rsp         ; Load the address of the stack top into rdi
 call gets            ; Call gets to read a string from user input
 xor rdi, rdi         ; Clear rdi register (set to zero)
 xor rsi, rsi         ; Clear rsi register (set to zero)
 mov rdi, rsp         ; Move stack pointer to rdi for strlen call
 call strlen          ; Call strlen to get the length of the string
 dec rax              ; Decrement the length to point to the last character
 xor rdi, rdi         ; Clear rdi register again
 mov r10, [rsp+rax]   ; Load the byte at the end of the string into r10
 cmp r10 , 115        ; Compare the byte with ASCII value for 's' (115)
 je signed            ; Jump to signed if the byte is 's'
 jne unsigned         ; Jump to unsigned if the byte is not 's'
 ret                  ; Return if neither 's' nor 'u' are matched

signed:
 mov rdi, rsp         ; Load stack pointer into rdi for atoi call
 call atoi            ; Call atoi to convert string to integer
 xor rdi, rdi         ; Clear rdi register
 mov r10, rax         ; Move the result of atoi to r10
 mov r11, rax         ; Move the result of atoi to r11
 shr r10, 14          ; Shift r10 right by 14 bits (extract part of the number)
 and r10, 0xF         ; Mask the lower 4 bits of r10
 shr r11, 20          ; Shift r11 right by 20 bits (extract part of the number)
 and r11, 0xF         ; Mask the lower 4 bits of r11
 mov r8, r10          ; Move the result of r10 to r8
 and r8 , 0x8         ; Mask the 3rd bit of r8 (check if the bit is set)
 cmp r8 , 0           ; Compare if the 3rd bit is 0
 jne setr10           ; Jump to setr10 if the 3rd bit of r10 is set
 jmp second           ; Jump to second if 3rd bit of r10 is not set

second:
 mov r8, r11          ; Move the result of r11 to r8
 and r8 , 0x8         ; Mask the 3rd bit of r8 (check if the bit is set)
 cmp r8 , 0           ; Compare if the 3rd bit is 0
 jne setr11           ; Jump to setr11 if the 3rd bit of r11 is set
 jmp end              ; Jump to end if 3rd bit of r11 is not set

end:
 mov rdi, printf_format ; Load printf format string into rdi
 mov rsi, r10          ; Load r10 into rsi (first argument to printf)
 mov rdx, r11          ; Load r11 into rdx (second argument to printf)
 add r10 , r11         ; Add r10 and r11 and store result in r10
 mov rcx, r10          ; Move the result to rcx (third argument to printf)
 call printf           ; Call printf to print the result
 mov rax, rsp          ; Restore the stack pointer to rax
 ; you can see allignment better using this line 
 ; calculate return code % 16 and see the 0
 add rsp, 40           ; Adjust the stack pointer by 40 to clean up
 ret                   ; Return from function

setr10:
 mov r12, 16           ; Set r12 to 16
 sub r12 , r10         ; Subtract r10 from 16
 neg r12               ; Negate r12 to get the 2's complement (sign extension)
 mov r10, r12          ; Move the result back into r10
 jmp second            ; Jump to second

setr11:
 mov r12, 16           ; Set r12 to 16
 sub r12 , r11         ; Subtract r11 from 16
 neg r12               ; Negate r12 to get the 2's complement (sign extension)
 mov r11, r12          ; Move the result back into r11
 jmp end               ; Jump to end

unsigned:
 mov rdi, rsp         ; Load stack pointer into rdi for atoi call
 call atoi            ; Call atoi to convert string to integer
 mov r10, rax         ; Move the result of atoi to r10
 mov r11, rax         ; Move the result of atoi to r11
 shr r10, 14          ; Shift r10 right by 14 bits (extract part of the number)
 and r10, 0xF         ; Mask the lower 4 bits of r10
 shr r11, 20          ; Shift r11 right by 20 bits (extract part of the number)
 and r11, 0xF         ; Mask the lower 4 bits of r11
 mov rdi, printf_format ; Load printf format string into rdi
 mov rsi, r10          ; Load r10 into rsi (first argument to printf)
 mov rdx, r11          ; Load r11 into rdx (second argument to printf)
 add r10 , r11         ; Add r10 and r11 and store result in r10
 mov rcx, r10          ; Move the result to rcx (third argument to printf)
 call printf           ; Call printf to print the result
 mov rax, rsp          ; Restore the stack pointer to rax
 ; you can see allignment better using this line 
 ; calculate return code % 16 and see the 0
 add rsp, 40           ; Adjust the stack pointer by 40 to clean up
 ret                   ; Return from function

section .data
 debug: db "%d", 10, 0            ; Format string for printing integers
 scanf_format: db "%s", 0,        ; Format string for input (string)
 printf_format: db "%d", 10 , "%d",10 , "%d" ,10,0 ; Format string for printf
