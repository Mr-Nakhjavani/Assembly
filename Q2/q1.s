global asm_main
extern printf 
extern scanf
extern strlen
extern atoi

section .text

asm_main:
	sub rsp, 40             ; Allocate 40 bytes on the stack for local variables

	; Read dimensions of matrices (m, n, p) using scanf
	mov rdi, scanf_format   ; Format for reading three integers
	lea rsi, [rsp]          ; Address of m
	lea rdx, [rsp+8]        ; Address of n
	lea rcx, [rsp+16]       ; Address of p
	call scanf

	; Prepare to read elements for the first matrix
	mov r15, -1             ; Initialize counter for matrix1 elements
	mov r14 , [rsp]         ; m (number of rows in matrix1)
	imul r14, [rsp+8]       ; r14 = m * n (total elements in matrix1)

scan1:    
	inc r15                 ; Increment element index
	cmp r15, r14            ; Check if all elements are read
	je setup2               ; If yes, move to reading the second matrix
	mov rdi, element        ; Format for reading an integer
	lea rsi, [matrix1 + (r15*8)] ; Address for the current element in matrix1
	call scanf              ; Read the element
	jmp scan1               ; Loop back to read the next element

setup2:
	; Prepare to read elements for the second matrix
	mov r15, -1             ; Reset counter for matrix2 elements
	mov r14, [rsp+8]        ; n (number of rows in matrix2)
	imul r14, [rsp+16]      ; r14 = n * p (total elements in matrix2)

scan2:
	inc r15                 ; Increment element index
	cmp r15, r14            ; Check if all elements are read
	je PROGRAM              ; If yes, proceed to the main program
	mov rdi, element        ; Format for reading an integer
	lea rsi, [matrix2 + (r15*8)] ; Address for the current element in matrix2
	call scanf              ; Read the element
	jmp scan2               ; Loop back to read the next element

PROGRAM:
	; Prepare for matrix multiplication
	mov r15, [rsp]          ; r15 = m
	mov r14, [rsp+8]        ; r14 = n
	mov r13, [rsp+16]       ; r13 = p

	; Push arguments for multiply function
	push matrix3            ; Address of the result matrix
	push matrix2            ; Address of the second matrix
	push matrix1            ; Address of the first matrix
	push r13                ; p (columns of matrix2)
	push r14                ; n (columns of matrix1 / rows of matrix2)
	push r15                ; m (rows of matrix1)
	call multiply           ; Call the matrix multiplication function
	xor rdi , rdi
	xor rsi, rsi
	xor rcx, rcx
	xor rbx , rbx
	xor rax, rax
	; Prepare to print the result matrix
	mov r12, [rsp]          ; m (rows of the result matrix)
	mov r13, [rsp+16]       ; p (columns of the result matrix)
	mov r14, 0              ; Row counter

	rows:
		mov r15, 0              ; Column counter
		cols:
			mov r11, r14            ; r11 = row index
			imul r11, r13           ; r11 = row_index * p
			add r11, r15            ; r11 = row_index * p + col_index
			mov rdi, printelement   ; Format for printing an element
			mov rsi, [matrix3 + r11*8] ; Address of the current element
			call printf             ; Print the element
			inc r15                 ; Increment column counter
			cmp r15, r13            ; Check if all columns are printed
			jne cols                ; If not, continue printing columns

		; Print a newline after each row
		xor rsi, rsi            ; Clear rsi
		mov rdi, newLine        ; Newline character
		call printf             ; Print newline
		inc r14                 ; Increment row counter
		cmp r14, r12            ; Check if all rows are printed
		jne rows                ; If not, continue printing rows

	; Restore stack and return
	mov rax, rsp
	add rsp, 40             ; Deallocate stack space
	ret

multiply:
	; Retrieve arguments from the stack
	pop rax                 ; Return address
	pop r15                 ; m (rows of matrix1)
	pop r14                 ; n (columns of matrix1 / rows of matrix2)
	pop r13                 ; p (columns of matrix2)
	pop r8                  ; Address of matrix1
	pop r9                  ; Address of matrix2
	pop r10                 ;Address of matrix3
	push rax                ; Preserve return address

	; Matrix multiplication logic
	mov r11, 0              ; Row index (matrix1)
	i:
		mov r12, 0              ; Column index (matrix2)
		j:
			mov rbp, 0              ; Index for multiplication (k-loop)
			k:
				mov rax, r11            ; rax = row index
				imul rax, r14           ; rax = row_index * n
				add rax, rbp            ; rax = row_index * n + k
				mov rbx, rbp            ; rbx = k
				imul rbx, r13           ; rbx = k * p
				add rbx, r12            ; rbx = k * p + col_index
				mov rcx, r11            ; rcx = row index
				imul rcx, r13           ; rcx = row_index * p
				add rcx, r12            ; rcx = row_index * p + col_index
				mov rdi, [r8 + rax*8]   ; Element from matrix1
				imul rdi, [r9 + rbx*8]  ; Multiply with element from matrix2
				add [r10 + rcx*8], rdi  ; Add result to matrix3
				inc rbp                 ; Increment k
				cmp rbp, r14            ; Check if k < n
				jne k                   ; If yes, continue k-loop

			inc r12                 ; Increment column index
			cmp r12, r13            ; Check if all columns are processed
			jne j                   ; If not, continue j-loop

		inc r11                 ; Increment row index
		cmp r11, r15            ; Check if all rows are processed
		jne i                   ; If not, continue i-loop

	; Return to caller
	mov rax, rsp
	ret

section .data
	matrix1: times 128 dq 0    ; Memory for the first matrix
	matrix2: times 128 dq 0    ; Memory for the second matrix
	matrix3: times 128 dq 0    ; Memory for the result matrix
	scanf_format: db "%d %d %d", 0 ; Format string for scanf
	element: db "%d", 0        ; Format string for matrix elements
	newLine: db 10, 0          ; Newline character
	printelement: db "%d ", 0  ; Format string for printf
