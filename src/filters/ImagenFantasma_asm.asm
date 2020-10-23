; defines
section .data
; constantes
i: times 4 DD 0
j: DD 0, 1, 2, 3
; blue0 = 00 ceros = 80 green0 = 01 ceros = 80 red0 = 02 ceros = 80 green0 = 01 ceros = 80 blue1 = 04 ceros = 80 green1 = 05 ceros = 80 red1 = 06 ceros = 80 green1 = 05 ceros = 80
; extiende_y_copia_green_bajo: DQ 0x8001800280018000, 0x8005800680058004
extiende_y_copia_green_pixeles_bajos: DB 0x00, 0x80, 0x80, 0x80, 0x01, 0x80, 0x80, 0x80, 0x02, 0x80, 0x80, 0x80, 0x01, 0x80, 0x80, 0x80
extiende_y_copia_green_pixeles_altos: DB 0x04, 0x80, 0x80, 0x80, 0x05, 0x80, 0x80, 0x80, 0x06, 0x80, 0x80, 0x80, 0x05, 0x80, 0x80, 0x80

section .text

extern ImagenFantasma_c
global ImagenFantasma_asm

ImagenFantasma_asm:
; rdi = src
; rsi = dst
; edx = width
; ecx = height
; r8d = src_row_size
; r9d = dst_row_size
; despues de armar el stackframe:
; rbp + 16 = offsetx
; rbp + 24 = offsety

	push rbp
	mov rbp, rsp
	push rbx
	push r12
	push r13
	push r14
	push r15
	sub rsp, 8
	
	mov rbx, rdi						; rbx  = src
	mov r12, rsi						; r12  = dst
	mov r13d, edx						; r13d = width 
	mov r14d, ecx						; r14d = height
	xor r8, r8							; indice i
	xor r9, r9							; indece j
	; rdx, rcx, r15 libres
	movdqa xmm15, [extiende_y_copia_green_pixeles_bajos]	; mascara para copiar componente green en transparencia y extender las componentes de bytes a DW de los primeros 2 pixeles
	movdqa xmm14, [extiende_y_copia_green_pixeles_altos]	; mismo que arriba para los siguientes 2 pixeles



	.ciclo:
		
		mov edx, r8d						;
		shr edx, 1							; edx  = i/2
		mov r15d, [rbp + 16]				; r15d = offset x
		add edx, r15d						; edx  = i/2 + offset x 
		
		.cicloHorizontal
			mov ecx, r9d
			shr ecx, 1
			mov r15d, [rbp + 24]
			add ecx, rbp

			;movdqu xmm0, [rdi + rbp + rci]

	

	movdqu xmm0, [rdi + offset]				; xmm0 = p3 | p2 | p1 | p0
	movdqu xmm1, xmm0						; xmm1 = p3 | p2 | p1 | p0	
	movdqu xmm2, xmm0
	
	pshufb xmm1, xmm15						; xmm1 = ii = g1 | r1 | g1 | b1 | g0 | r0 | g0 | b0 <- componentes en words del pixel 1, 0 
	;pshufb xmm2, xmm14						; xmm2 = g3 | r3 | g3 | b3 | g2 | r2 | g2 | b2 <- componentes en words del pixel 3, 2

	phaddw xmm1, xmm1						; xmm1 = 

	add rsp, 8
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbx
	pop rbp
ret
