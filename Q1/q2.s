global asm_main
extern printf 
extern scanf
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
	mov rdi, scanf_format ; Load the address of the stack top into rdi
	lea rsi, [rsp]
	lea rdx, [rsp+20]
	call scanf
	cmp rax , 2
	jne invalid
	mov r10, [rsp]
	mov r11, [rsp + 20]
	jmp progress

	
invalid:
	mov rdi, invalid_format
	call printf
	mov rax, rsp
	add rsp, 40       
	ret
	
	
progress:
	
	mov rax, r10
	mov rbx, r11
	call comb

	
	mov rdi, printf_format
	mov rsi, rcx
	call printf

	mov rax, rsp
	add rsp, 40
	ret


comb:
	
	cmp rbx, 0
	jl negative

	
	cmp rbx, rax
	jg bigger_than_n

	
	cmp rbx, 1
	je one

	
	cmp rbx, 0
	je zero

	
	cmp rbx, rax
	je equal

choose:
	dec rax
	push rax
	push rbx
	call comb ;n = n-1, r = r
	pop rbx
	pop rax
	push rcx ;c(n-1, r)
	dec rbx
	push rax
	push rbx
	call comb ;n = n-1, r = r-1
	pop rbx
	pop rax
	push rcx ;c(n-1, r-1)
	pop rax
	pop rcx
	add rcx, rax ;c(n,r) = c(n-1, r) + c(n-1, r-1)
	ret

one:
	mov rcx, rax
	ret

zero:
	mov rcx, 1
	ret

equal:
	mov rcx, 1
	ret
    
negative:
	mov rcx, 0
	ret

bigger_than_n:
	mov rcx, 0
	ret
section .data
	invalid_format: db "invalid input!", 10 , 0
	debug: db "%d", 10, 0            ; Format string for printing integers
	scanf_format: db "%d %d", 0,  ; Format string for input (string)
	printf_format: db "%d",10,0 ; Format string for printf
