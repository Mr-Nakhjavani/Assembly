global asm_main
extern printf 
extern scanf
extern strlen
extern atoi

section .text

asm_main:
	sub rsp, 40             ; Allocate 40 bytes on the stack for local variables

	; Read dimensions of matrices (m, n, p) using scanf
	mov rdi, scanf_format   ; Load the format string for scanf
	lea rsi, [rsp]          ; Address to store m
	lea rdx, [rsp+8]        ; Address to store n
	call scanf              ; Read input for m and n

	; Prepare to read elements for the first matrix
	mov r15, -1             ; Initialize the counter for elements of matrix1
	mov r14, [rsp]          ; Load m (rows of matrix1)
	imul r14, [rsp+8]       ; Calculate m * n (total elements in matrix1)

scan1:    
	inc r15                 ; Increment element index
	cmp r15, r14            ; Check if all elements are read
	je setup2               ; Jump to setup2 if all elements are read
	mov rdi, element        ; Format for reading a single element
	lea rsi, [matrix1 + (r15*8)] ; Address for the current element in matrix1
	call scanf              ; Read the element
	jmp scan1               ; Repeat for the next element

setup2:
	; Prepare to read elements for the second matrix
	mov r15, -1             ; Reset the counter for elements of matrix2
	mov r14, [rsp]          ; Load m (rows of matrix2)
	imul r14, [rsp+8]       ; Calculate m * n (total elements in matrix2)

scan2:
	inc r15                 ; Increment element index
	cmp r15, r14            ; Check if all elements are read
	je PROGRAM              ; Jump to the main program if done
	mov rdi, element        ; Format for reading a single element
	lea rsi, [matrix2 + (r15*8)] ; Address for the current element in matrix2
	call scanf              ; Read the element
	jmp scan2               ; Repeat for the next element

PROGRAM:
	mov r15, [rsp]          ; Load m
	mov r14, [rsp+8]        ; Load n
	push matrix1            ; Push matrix1 onto the stack
	push r14                ; Push n onto the stack
	push r15                ; Push m onto the stack
	call transpose          ; Call the transpose function

	mov r15, [rsp]          ; Load m after transpose
	mov r14, [rsp+8]        ; Load n after transpose
	push matrix3            ; Push matrix3 onto the stack
	push matrix2            ; Push matrix2 onto the stack
	push matrix1t           ; Push matrix1 transpose onto the stack
	push r14                ; Push n onto the stack
	push r15                ; Push m onto the stack
	call multiply           ; Call the multiply function

	; Summing the diagonal elements of the resulting matrix
	mov r13, 0              ; Initialize sum to 0
	mov r12, [rsp+8]        ; Load the number of columns
	mov r14, 0              ; Row counter
rows:
	mov r15, 0              ; Column counter
cols:
	cmp r14, r15            ; Check if row index equals column index
	jne next                ; Skip if not on the diagonal
add: 
	mov rcx, r14            ; Row index
	imul rcx, r12           ; Calculate the offset for the row
	add rcx, r15            ; Add the column index
	add r13, [matrix3 + rcx*8] ; Add the diagonal element to the sum
next:
	inc r15                 ; Increment column index
	cmp r15, r12            ; Check if all columns are processed
	jne cols                ; Repeat for the next column
	inc r14                 ; Increment row index
	cmp r14, r12            ; Check if all rows are processed
	jne rows                ; Repeat for the next row

	; Print the sum of diagonal elements
	xor rdi, rdi            ; Clear rdi
	xor rsi, rsi            ; Clear rsi
	xor rcx, rcx            ; Clear rcx
	xor rbx, rbx            ; Clear rbx
	xor rax, rax            ; Clear rax
	mov rdi, print          ; Format string for printing
	mov rsi, r13            ; Load the sum to be printed
	call printf             ; Print the sum

	; Restore stack and return
	mov rax, rsp            ; Restore rsp to its original value
	add rsp, 40             ; Deallocate stack space
	ret                     ; Return to the caller

multiply:
	; Retrieve arguments from the stack
	pop rax                 ; Return address
	pop r15                 ; Number of rows inmatrix1
	pop r14                 ; Number of columns in matrix1 (and rows in matrix2)
	pop r8                  ; Address of matrix1 transpose
	pop r9                  ; Address of matrix2
	pop r10                 ; Address of matrix3
	push rax                ; Preserve return address

	; Matrix multiplication logic
	mov r11, 0              ; Row index for matrix1 transpose
i:
	mov r12, 0              ; Column index for matrix2
j:
	mov rbp, 0              ; Index for the multiplication loop
k:
	mov rax, r11            ; Load row index
	imul rax, r15           ; Multiply by the number of columns
	add rax, rbp            ; Add the current index
	mov rbx, rbp            ; Load the current index
	imul rbx, r14           ; Multiply by the number of columns in matrix2
	add rbx, r12            ; Add the column index
	mov rcx, r11            ; Load the row index
	imul rcx, r14           ; Multiply by the number of columns in matrix3
	add rcx, r12            ; Add the column index
	mov rdi, [r8 + rax*8]   ; Load an element from matrix1 transpose
	imul rdi, [r9 + rbx*8]  ; Multiply with an element from matrix2
	add [r10 + rcx*8], rdi  ; Add the result to the current element in matrix3
	inc rbp                 ; Increment the multiplication index
	cmp rbp, r15            ; Check if the loop is complete
	jne k                   ; Repeat if not

	inc r12                 ; Increment the column index
	cmp r12, r14            ; Check if all columns are processed
	jne j                   ; Repeat if not

	inc r11                 ; Increment the row index
	cmp r11, r14            ; Check if all rows are processed
	jne i                   ; Repeat if not

	ret                     ; Return to the caller

transpose:
	pop rax                 ; Return address
	pop r15                 ; Number of rows
	pop r14                 ; Number of columns
	pop r8                  ; Address of matrix1
	push rax                ; Preserve return address
	mov r12, 0              ; Row index for transpose
i2:
	mov r13, 0              ; Column index for transpose
j2:
	mov rax, r12            ; Load row index
	imul rax, r14           ; Multiply by the number of columns
	add rax, r13            ; Add the column index
	mov rbx, r13            ; Load the column index
	imul rbx, r15           ; Multiply by the number of rows
	add rbx, r12            ; Add the row index
	mov rcx, [matrix1 + rax*8] ; Load an element from matrix1
	add [matrix1t + rbx*8], rcx ; Write the transposed element to matrix1 transpose
	inc r13                 ; Increment the column index
	cmp r13, r14            ; Check if all columns are processed
	jne j2                  ; Repeat if not
	inc r12                 ; Increment the row index
	cmp r12, r15            ; Check if all rows are processed
	jne i2                  ; Repeat if not
	ret                     ; Return to the caller

section .data
	matrix1: times 128 dq 0    ; Memory allocation for the first matrix
	matrix1t: times 128 dq 0   ; Memory allocation for the transpose of matrix1
	matrix2: times 128 dq 0    ; Memory allocation for the second matrix
	matrix3: times 128 dq 0    ; Memory allocation for the result matrix
	scanf_format: db "%d %d", 0 ; Format string for scanf to read two integers
	element: db "%d", 0        ; Format string for reading individual matrix elements
	print: db "%d", 10 , 0     ; Format string for printing integers
