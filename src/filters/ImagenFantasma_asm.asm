; defines
section .data
; constantes
align 16
; blue0 = 00 ceros = 80 green0 = 01 ceros = 80 red0 = 02 ceros = 80 green0 = 01 ceros = 80 blue1 = 04 ceros = 80 green1 = 05 ceros = 80 red1 = 06 ceros = 80 green1 = 05 ceros = 80
; extiende_y_copia_green_bajo: DQ 0x8001800280018000, 0x8005800680058004
extiende_y_copia_green_pixeles_bajos: DB 0x00, 0x80, 0x01, 0x80, 0x02, 0x80, 0x01, 0x80, 0x04, 0x80, 0x05, 0x80, 0x06, 0x80, 0x05, 0x80
limpia_DD_mas_significativa: DD 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0x00000000
divisor_8: times 4 DD 8
const_f: DD 0.9, 0.9, 0.9, 1  
transparencias: times 4 DD 0xFF000000

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
	
	mov rbx, rdi						; rbx  = src
	mov r12, rsi						; r12  = dst
	mov r13d, edx						; r13d = width 
	mov r14d, ecx						; r14d = height
	mov edx, [rbp + 16]					; edx = offset_x
	mov ecx, [rbp + 24]					; ecx = offset_y
	xor r8, r8							; r8d  = indice i
	xor r9, r9							; r9d  = indece j
	movdqa xmm15, [extiende_y_copia_green_pixeles_bajos]	; mascara para copiar componente green en transparencia y extender las componentes de bytes a DW de los primeros 2 pixeles
	movaps xmm14, [divisor_8]
	movaps xmm13, [const_f]
	movdqa xmm12, [transparencias]

	pxor xmm10, xmm10
											; explicacion de las siguientes 2 lineas:
											;	como a nivel memoria la matriz img no es mas que un arreglo => 
											;	matriz[ii][jj] = dir inicial + ii*4 + jj*4 <=> dir inicial + (i/2 + offset_X)*4 + (j/2 + offset+y)*4
											;	<=> dir inicial + (i/2)*4 + (j/2)*4 + offset_x*4 + offset_y*4
											; entonces puedo sumar el offset_x*4 y offset_y*4 y luego moverme por i/2 * 4 e j/2 * 4 

	mov eax, edx							; eax = offset_x
	xor rdx, rdx
	mul r13d								; edx::eax = n*offset_x
	shl rdx, 32
	or rdx, rax								; rdx = n*offset_x		<- movimiento en filas
	lea rsi, [rsi + rdx*4]					; rsi = dir + offset_x*n*4
	lea rsi, [rsi + rcx*4]					; rsi = dir + offset y 
	xor rdx, rdx
	xor rcx, rcx
	mov rsi, rdi
											; (nota personal) registros libres para usar: rdx, r15 
	.ciclo:		
		.cicloHorizontal:
			movdqu xmm0, [rdi + r9*4]		; xmm0 = p3 | p2 | p1 | p0, r9*4 es j*4, es decir el movimiento horizontal
			movq xmm1, [rsi + rcx*4]		; xmm1 = basura | basura | p1 | p0
											; Levantamos matriz[ii][jj] con la precondicion de que j sea par. 
											; Como j es par, podemos decir que parteEntera(j/2) == parteEntera((j+1)/2)
											; entonces j/2 + offset_y == (j+1)/2 + offset_y, luego habiendo fijado el indice i
											; para los pixeles j y j+1 solo necesitamos un jj
											; por ultimo si tomamos la (parte entera) mitad de cada entero volvemos a formar el conjunto de los enteros 
											; si a i e i+1 le corresponde ii => i+2 e i+3 le corresponde ii+1.
											; Teniendo en cuenta ambas condiciones podemos tomar 2 pixeles ii e ii+1 para trabajar los pixeles 
											; j, j+1, j+2 y j+3
			.armoB:
				pshufb xmm1, xmm15				; xmm1 = g1 | r1 | g1 | b1 | g0 | r0 | g0 | b0 | <- en words 
				phaddw xmm1, xmm1				; xmm1 = g1+r1 | g1+b1 | g0+r0 | g0+b0 | g1+r1 | g1+b1 | g0+r0 | g0+b0 |
				phaddw xmm1, xmm1				; xmm1 = g1+r1+g1+b1 | g0+r0+g0+b0 | g1+r1+g1+b1 | g0+r0+g0+b0 | g1+r1+g1+b1 | g0+r0+g0+b0 | g1+r1+g1+b1 | g0+r0+g0+b0
				punpcklwd xmm1, xmm10			; xmm1 = g1+r1+g1+b1 | g0+r0+g0+b0 | g1+r1+g1+b1 | g0+r0+g0+b0 <- b1 y b0 en dwords
				movdqu xmm2, xmm1				
				pshufd xmm1, xmm1, 0x00			; xmm1 = g0+r0+g0+b0 | g0+r0+g0+b0 | g0+r0+g0+b0 | g0+r0+g0+b0
				pshufd xmm2, xmm2, 0x55			; xmm2 = g1+r1+g1+b1 | g1+r1+g1+b1 | g1+r1+g1+b1 | g1+r1+g1+b1
				cvtdq2ps xmm1, xmm1				; convierto ambos vectores de int a floats
				cvtdq2ps xmm2, xmm2
				divps xmm1, xmm14				; xmm1 = basura | b0 / 8 | b0 / 8 | b0 / 8 
				divps xmm2, xmm14				; xmm2 = basura | b1 / 8 | b1 / 8 | b1 / 8

			.modificoLasComponentes:
				movdqu xmm3, xmm0
				movdqu xmm4, xmm0
				movdqu xmm5, xmm0
				punpcklbw xmm0, xmm10			
				punpcklwd xmm0, xmm10			; xmm0 = a0 | r0 | g0 | b0	<- px0 en dwords
				punpcklbw xmm3, xmm10
				punpcklwd xmm3, xmm10			; xmm3 = a1 | r1 | g1 | b1	<- px1 en dwords
				punpcklbw xmm4, xmm10
				punpcklwd xmm4, xmm10			; xmm4 = a2 | r2 | g2 | b2	<- px2 en dwords
				punpcklbw xmm5, xmm10
				punpcklwd xmm5, xmm10			; xmm5 = a3 | r3 | g3 | b3  <- px3 en dwords
				
				cvtdq2ps xmm0, xmm0				; xmm0 = a0 | r0 | g0 | b0	<- px0 en float simple 
				cvtdq2ps xmm3, xmm3				; xmm3 = a1 | r1 | g1 | b1	<- px1 en float simple 
				cvtdq2ps xmm4, xmm4				; xmm4 = a2 | r2 | g2 | b2	<- px2 en float simple 
				cvtdq2ps xmm5, xmm5				; xmm5 = a3 | r3 | g3 | b3  <- px3 en float simple 

				mulps xmm0, xmm13				; multiplico a todas las componentes por 0,9
				mulps xmm3, xmm13
				mulps xmm4, xmm13
				mulps xmm5, xmm13

				addps xmm0, xmm1				;
				addps xmm3, xmm1				; sumo las componentes de p0 y p1 con b0
				addps xmm4, xmm2
				addps xmm5, xmm2				; sumo las componentes de p2 y p3 con b1

				cvtps2dq xmm0, xmm0				
				cvtps2dq xmm3, xmm3
				cvtps2dq xmm4, xmm4
				cvtps2dq xmm5, xmm5				; transformo de float a dw signado (no tengo otra instruccion para no signado)

				packusdw xmm0, xmm3				; xmm0 = basura | r1 | g1 | b1 | basura | r0 | g0 | b0  <- pixel 0 y pixel 1 en unsigned words saturadas
				packusdw xmm4, xmm5				; xmm1 = basura | r3 | g3 | b3 | basura | r2 | g2 | b2  <- pixel 2 y pixel 3 en unsigned words saturadas  

				packuswb xmm0, xmm4				; xmm0 = basura | r3 | g3 | b3 | basura | r2 | g2 | b2 | basura | r1 | g1 | b1 | basura | r0 | g0 | b0

				por xmm0, xmm12				; xmm0 or (x4)0xFF000000 =   FF | r3 | g3 | b3 | FF | r2 | g2 | b2 | FF | r1 | g1 | b1 | FF | r0 | g0 | b0 

			movdqu [r12 + r9*4], xmm0

			add ecx, 2						; me muevo cada 2 pixeles en jj
			add r9d, 4						; me muevo 4 pixeles
			cmp r9d, r13d					; j == width?
			jz  .cambiarFila				; si llego al final de la fila, la cambio
		

		.cambiarFila:
			inc r8d
			cmp r8d, r14d					; i == height?
			jz .fin
			xor rcx, rcx					; reseteo los iteradores de columna
			xor r9, r9						
			lea rdi, [rdi + r13*4]			; rdi = dir + n*4      <- al tamanio de la fila le multiplico el tamanio de un dato
			lea r12, [r12 + r13*4]
			test r8d, 1						; i and 1, afecta el flag zero, si el ultimo bit de r8d es 0 entonces es un numero par
			jnz .cicloHorizontal				
			.cambiaII:
				lea rsi, [rsi + r13*4]			; por cada 2 filas tengo que aumentar ii por lo explicado arriba
				jmp .cicloHorizontal

	.fin:
		pop r14
		pop r13
		pop r12
		pop rbx
		pop rbp
ret
