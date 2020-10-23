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
	mov edx, [rbp + 16]
	mov ecx, [rbp + 24]
	xor r8, r8							; r8d  = indice i
	xor r9, r9							; r9d  = indece j
	; rdx, rcx, r15 libres
	movdqa xmm15, [extiende_y_copia_green_pixeles_bajos]	; mascara para copiar componente green en transparencia y extender las componentes de bytes a DW de los primeros 2 pixeles
	movdqa xmm14, [extiende_y_copia_green_pixeles_altos]	; mismo que arriba para los siguientes 2 pixeles


	mov rsi, rdi
	.ciclo:
		mov rdi, rbx
		mov rsi, rbx
		lea rdi, [rdi + r15d*4]				; rdi = dir + n*4      <- al tamanio de la fila le multiplico el tamanio de un dato
		lea rsi, [rsi + rdx*4]				; rsi = ii, en este caso rdx empieza con el offset x y se le va sumando width 
		
		.cicloHorizontal
			movdqu xmm0, [rdi + r9*4]		; xmm0 = p3 | p2 | p1 | p0, r9*4 es j*4, es decir el movimiento horizontal
			movq xmm1, [rsi + rcx*4]		; rsi xmm1 = basura | basura | p1 | p0
											; Levantamos matriz[ii][jj] con la precondicion de que j sea par. 
											; Como j es par, podemos decir que parteEntera(j/2) == parteEntera((j+1)/2)
											; entonces j/2 + offset_y == (j+1)/2 + offset_y, luego habiendo fijado el indice i
											; para los pixeles j y j+1 solo necesitamos un jj
											; por ultimo si tomamos la (parte entera) mitad de cada entero volvemos a formar el conjunto de los enteros 
											; si a i e i+1 le corresponde ii => i+2 e i+3 le corresponde ii+1.
											; Teniendo en cuenta ambas condiciones podemos tomar 2 pixeles ii e ii+1 para trabajar los pixeles 
											; j, j+1, j+2 y j+3

			add ecx, 2						; me muevo cada 2 pixeles en jj
			add r9d, 4						; me muevo 4 pixeles
			cmp r9d, r13d					; j == width?
			jz  .cambiarFila				; si llego al final de la fila, la cambio
		
		.cambiarFila:
			inc r8d
			cmp r8d, r14d					; i == height?
			jz .fin
			add r15d, r13d					; r15d = n+n <- sumo otra fila para cambiar de fila
			test r8d, 1						; i and 1, afecta el flag zero, si el ultimo bit de r8d es 0 entonces es un numero par
			jnz .ciclo
			add edx, r13d					; por cada 2 filas tengo que aumentar ii por lo explicado arriba
			jmp .ciclo

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
