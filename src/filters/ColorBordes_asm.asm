section .data
align 16
; fila generica : a3 | r3 | g3 | b3 | a2 | r2 | g2 | b2 | a1 | r1 | g1 | b1 | a0 | r0 | g0 | b0
;                 0f   0e   0d   0c   0b   0a   09   08   07   06   05   04   03   02   01   00
reordena_datos_ii_px1: DB 0x00, 0x80, 0x08, 0x80, 0x01, 0x80, 0x09, 0x80, 0x03, 0x80, 0x0A, 0x80, 0x80, 0x80, 0x80, 0x80  
reordena_datos_ii_px2: DB 0x04, 0x80, 0x0C, 0x80, 0x05, 0x80, 0x0D, 0x80, 0x06, 0x80, 0x0E, 0x80, 0x80, 0x80, 0x80, 0x80
transparencias: times 4 DD 0xFF000000
section .text

extern ColorBordes_c
global ColorBordes_asm

ColorBordes_asm:
; rdi = src*
; rsi = dst*
; edx = width
; ecx = height
; r8d = src_row_size
; r9d = dst_row_size
	push rbp
	mov rbp, rsp
	push rbx
	push r12
	push r13
	push r14
	push r15
	sub rsp, 8

	mov rbx, rdi	; rbx  = src*
	mov r12, rsi	; r12  = dst*
	mov r13d, edx	; r13d = width
	mov r14d, ecx	; r14d = height
	mov r15d, r8d	; r15d = src_row_size

	movdqa xmm15, [reordena_datos_ii_px1]
	movdqa xmm14, [reordena_datos_ii_px2]
	movdqa xmm13, [transparencias]

	lea rsi, [rsi + r8 + 4]				; rsi = m[1][1]
	


	.ciclo:
		movdqu xmm0, [rdi]				; xmm0 =  p[i-1][j+2] | p[i-1][j+1] | p[i-1][j] | p[i-1][j-1]  
		lea rdi, [rdi + r8*2]			; rdi = matriz[i+1][j-1]
		movdqu xmm2, [rdi]				; xmm2 = p[i+1][j+2] | p[i+1][j+1] | p[i+1][j] | p[i+1][j-1]
		sub rdi, r8						; rdi = matriz[i][j-1]
		movdqu xmm1, [rdi]				; xmm1 = p[i][j+2] | p[i][j+1] | p[i][j] | p[i][j-1]

		movdqa xmm3, xmm0				; copio las filas que uso para el ciclo ii del px0
		movdqa xmm4, xmm1
		movdqa xmm5, xmm2				
		movdqa xmm6, xmm0				; copio las filas que uso para el ciclo ii del px1
		movdqa xmm7, xmm1
		movdqa xmm8, xmm2				
										; px0:
		pshufb xmm3, xmm15				; xmm3 = 0 | 0 | p[i-1][j+1].r | p[i-1][j-1].r | p[i-1][j+1].g | p[i-1][j-1].g | p[i-1][j+1].b | p[i-1][j-1].b
		pshufb xmm4, xmm15				; xmm4 = 0 | 0 | p[i][j+1].r | p[i][j-1].r | p[i][j+1].g | p[i][j-1].g | p[i][j+1].b | p[i][j-1].b
		pshufb xmm5, xmm15				; xmm5 = 0 | 0 | p[i+1][j+1].r | p[i+1][j-1].r | p[i+1][j+1].g | p[i+1][j-1].g | p[i+1][j+1].b | p[i+1][j-1].b
										; px1:
		pshufb xmm6, xmm14				; xmm6 = 0 | 0 | p[i-1][j+2].r | p[i-1][j].r | p[i-1][j+2].g | p[i-1][j].g | p[i-1][j+2].b | p[i-1][j].b
		pshufb xmm7, xmm14				; xmm7 = 0 | 0 | p[i][j+2].r | p[i][j].r | p[i][j+2].g | p[i][j].g | p[i][j+2].b | p[i][j].b
		pshufb xmm8, xmm14				; xmm8 = 0 | 0 | p[i+1][j+2].r | p[i+1][j].r | p[i+1][j+2].g | p[i+1][j].g | p[i+1][j+2].b | p[i+1][j].b

		.cicloIi:
			.px0Resta:
				phsubw xmm3, xmm3			; xmm3 = basura | basura | basura | basura | 0 | m[i-1][j-1].r - m[i-1][j+1].r | m[i-1][j-1].g - m[i-1][j+1].g | m[i-1][j-1].b - m[i-1][j+1].b
				phsubw xmm4, xmm4			; xmm4 = basura | basura | basura | basura | 0 | m[i][j-1].r - m[i][j+1].r | m[i][j-1].g - m[i][j+1].g | m[i][j-1].b - m[i][j+1].b
				phsubw xmm5, xmm5 			; xmm5 = basura | basura | basura | basura | 0 | m[i+1][j-1].r - m[i+1][j+1].r | m[i+1][j-1].g - m[i+1][j+1].g | m[i+1][j-1].b - m[i+1][j+1].b
			
			.px1Resta:		
				phsubw xmm6, xmm6
				phsubw xmm7, xmm7 
				phsubw xmm8, xmm8			

			.absIi:
				pabsw xmm3, xmm3			; xmm3 = basura | basura | basura | basura | 0 | abs(m[i-1][j-1].r - m[i-1][j+1].r) | abs(m[i-1][j-1].g - m[i-1][j+1].g) | abs(m[i-1][j-1].b - m[i-1][j+1].b)
				pabsw xmm4, xmm4			; xmm4 = basura | basura | basura | basura | 0 | abs(m[i][j-1].r - m[i][j+1].r) | abs(m[i][j-1].g - m[i][j+1].g) | abs(m[i][j-1].b - m[i][j+1].b)
				pabsw xmm5, xmm5			; xmm5 = basura | basura | basura | basura | 0 | abs(m[i+1][j-1].r - m[i+1][j+1].r) | abs(m[i+1][j-1].g - m[i+1][j+1].g) | abs(m[i+1][j-1].b - m[i+1][j+1].b)

				pabsw xmm6, xmm6
				pabsw xmm7, xmm7
				pabsw xmm8, xmm8			

			.sumaDeRestasIi:
				paddusw xmm3, xmm4
				paddusw xmm3, xmm5			; xmm3 = basura | basura | basura | basura | 0 | px0_ii_r | px0_ii_g | px0_ii_b

				paddusw xmm6, xmm7
				paddusw xmm6, xmm8			; xmm6 = basura | basura | basura | basura | 0 | px1_ii_r | px1_ii_g | px1_ii_b

				movdqa xmm4, xmm6			; xmm4 = basura | basura | basura | basura | 0 | px1_ii_r | px1_ii_g | px1_ii_b

		movdqa xmm5, xmm0		
		movdqa xmm6, xmm0					; guardo las filas i-1 e i+1
		movdqa xmm7, xmm2
		movdqa xmm8, xmm2					; realizo lo mismo solo que estas dos ultimas seran para sumar jj = j + 1

		punpcklbw xmm5, xmm12				; xmm5 = m[i-1][j].a | m[i-1][j].r | m[i-1][j].g | m[i-1][j].b | m[i-1][j-1].a | m[i-1][j-1].r | m[i-1][j-1].g | m[i-1][j-1].b
		punpckhbw xmm6, xmm12				; xmm6 = m[i-1][j+2].a | m[i-1][j+2].r | m[i-1][j+2].g | m[i-1][j+2].b | m[i-1][j+1].a | m[i-1][j+1].r | m[i-1][j+1].g | m[i-1][j+1].b
		punpcklbw xmm7, xmm12				; xmm7 = m[i+1][j].a | m[i+1][j].r | m[i+1][j].g | m[i+1][j].b | m[i+1][j-1].a | m[i+1][j-1].r | m[i+1][j-1].g | m[i+1][j-1].b
		punpckhbw xmm8, xmm12				; xmm8 = m[i+1][j+2].a | m[i+1][j+2].r | m[i+1][j+2].g | m[i+1][j+2].b | m[i+1][j+1].a | m[i+1][j+1].r | m[i+1][j+1].g | m[i+1][j+1].b

		.cicloJj:
			.restaJj:
				psubsw xmm5, xmm7			; xmm5 = basura | m[i-1][j].r - m[i+1][j].r | m[i-1][j].g - m[i+1][j].g | m[i-1][j].b - m[i+1][j].b | basura | m[i-1][j-1].r - m[i+1][j-1].r | m[i-1][j-1].g - m[i+1][j-1].g | m[i-1][j-1].b - m[i+1][j-1].b 
				psubsw xmm6, xmm8			; xmm6 = basura | m[i-1][j+2].r - m[i+1][j+2].r | m[i-1][j+2].g - m[i+1][j+2].g | m[i-1][j+2].b - m[i+1][j+2].b | basura | m[i-1][j+1].r - m[i+1][j+1].r | m[i-1][j+1].g - m[i+1][j+1].g | m[i-1][j+1].b - m[i+1][j+1].b 
		
			.absJj:
				pabsw xmm5, xmm5				
				pabsw xmm6, xmm6

			.sumaDeRestasJj:
				movdqa xmm7, xmm5			
				psrldq xmm7, 8				; xmm7 = basura | basura | basura | basura | basura | m[i-1][j].r - m[i+1][j].r | m[i-1][j].g - m[i+1][j].g | m[i-1][j].b - m[i+1][j].b 
				paddusw xmm7, xmm5			
				paddusw xmm7, xmm6			; xmm7 = basura | basura | basura | basura | basura | px0_jj_r | px0_jj_g | px0_jj_b

				movdqa xmm8, xmm6
				pslldq xmm8, 8				; xmm8 = basura | m[i-1][j+1].r - m[i+1][j+1].r | m[i-1][j+1].g - m[i+1][j+1].g | m[i-1][j+1].b - m[i+1][j+1].b | basura | basura | basura | basura   
				paddusw xmm8, xmm6
				paddusw xmm8, xmm5			; xmm8 = basura | px1_jj_r | px1_jj_g | px1_jj_b | basura | basura | basura | basura
				psrldq xmm8, 8				; xmm8 = basura | basura | basura | basura | basura | px1_jj_r | px1_jj_g | px1_jj_b 

		paddusw xmm3, xmm7					; xmm3 = basura | basura | basura | basura | basura | px0_r | px0_g | px0_b
		paddusw xmm4, xmm8					; xmm4 = basura | basura | basura | basura | basura | px1_r | px1_g | px1_b
		pslldq xmm3, 10
		pslldq xmm4, 10
		psrldq xmm3, 10						; xmm3 = 0 |   0   |   0   |   0   | 0 | px0_r | px0_g | px0_b
		psrldq xmm4, 2						; xmm4 = 0 | px1_r | px1_g | px1_b | 0 |   0   |   0   |   0
		por xmm3, xmm4						; xmm3 = 0 | px1_r | px1_g | px1_b | 0 | px0_r | px0_g | px0_b
		packuswb xmm3, xmm12
		por xmm3, xmm13						; seteo transparencias

		movq [rsi], xmm3
		add 
		

	add rsp, 8
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbx
	pop rbp
ret
