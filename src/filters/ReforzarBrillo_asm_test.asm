extern ReforzarBrillo_c
global ReforzarBrillo_asm

section .rodata
    align 16
	; ceros = 80 green1 = 05 ceros = 80 red1 = 06 ceros = 80 green1 = 05 ceros = 80 blue1 = 04 ceros = 80 green = 01 ceros = 80 red = 02 ceros = 80 green = 01 ceros = 80 blue0 = 00
	extiende_y_copia_green_bajo: DQ 0x8001800280018000, 0x8005800680058004
	; extiende_y_copia_green_alto: DQ 0x8009800A80098008, 0x800D800E800D800C

section .text

ReforzarBrillo_asm:
    ; rdi = *src
    ; rsi = *dst
    ; edx = width 
    ; ecx = height
    ; r8d = src_row_size
    ; r9d = dst_row_size
    ; [rbp+16] = umbralSup
    ; [rbp+24] = umbralInf
    ; [rbp+32] = brilloSup
    ; [rsp+40] = brilloInf

    push rbp
    mov rbp, rsp    ; StackFrame

    pxor xmm9, xmm9

    xor rdx, rdx
    mov eax, r8d 
    mul ecx
    shl rdx, 32
    or rax, rdx
    
    .ciclo_brillos:
        movdqa xmm15, [extiende_y_copia_green_bajo]

        movd xmm14, [rbp + 16]      ; Muevo umbralSup a la parte baja xmm13
        pshufd xmm14, xmm14, 0x00   ; [ umbralSup | umbralSup | umbralSup | umbralSup ]

        movd xmm13, [rbp + 24]      ; Muevo umbralInf a la parte baja de xmm12
        pshufd xmm13, xmm13, 0x00   ; [ umbralInf | umbralInf | umbralInf | umbralInf ]

        movd xmm12, [rbp + 32]      ; Muevo umbralSup a la parte baja de xmm11
        pshufd xmm12, xmm12, 0x00   ; [ brilloSup | brilloSup | brilloSup | brilloSup ]

        movd xmm11, [rbp + 40]      ; Muevo umbralInf a la parte baja de xmm10
        pshufd xmm11, xmm11, 0x00   ; [ brilloInf | brilloInf | brilloInf | brilloInf ]
        
        cmp rax, 0
        je .fin
        cmp rax, 8
        jne .levanto_pixeles
        movq xmm0, [rdi]
        jmp .procesado


        .levanto_pixeles:
        movdqu xmm0, [rdi]  ; xmm0 = [ a_3 | r_3 | g_3 | b_3 | ... ]
        
        .procesado:
        movdqa xmm1, xmm0
        pshufb xmm0, xmm15  ; xmm0 = [ pixel 1 | pixel 0 ] y con el formato [ G | R | G | B ] para facilitar la suma
        
        ; ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

        phaddw xmm0, xmm9   ; xmm0 = [ 0 | 0 | 0 | 0 | G + R (pixel1) | G + B (pixel1) | G + R (pixel0) | G + B (pixel0) ]

        phaddw xmm0, xmm9   ; xmm0 = [ 0 | 0 | 0 | 0 | 0 | 0 | R + 2G + B (pixel1) | R + 2G + B (pixel0) ]

        psrlw xmm0, 2           ; xmm0 = [ 0 | 0 | 0  | 0  | 0  | 0  | (R + 2G + B)/4 (b de pixel1) | (R + 2G + B)/4 (b de pixel0) ]
        pmovzxwd xmm0, xmm0     ; xmm0 = [ 0 | 0 | B1 | B2 ]
        movdqa xmm3, xmm0       ; copia

        pcmpgtd xmm3, xmm14 ; xmm3 = [ 0 | 0 | b1 > umbralSup) | b0 > umbralSup) ]
        
        movdqa xmm4, xmm13  ; copia
        pcmpgtd xmm4, xmm0  
        movdqa xmm0, xmm4   ; xmm0 = [ 0 | 0 | b1 < umbralInf | b0 < umbralInf ]        

        pand xmm3, xmm12    
        pslldq xmm3, 8
        psrldq xmm3, 8      ; xmm3 = [ 0 | 0 | brillSup (si b1 > uS) | brilloSup (si b0 > uS) ]

        pand xmm0, xmm11    
        pslldq xmm0, 8
        psrldq xmm0, 8      ; xmm0 = [ 0 | 0 | brillInf (si b1 < uI) | brilloInf (si b0 < uI) ]

        ; /////////////////////////////////////////////////////////////////////////////////////////////////////////////

        packusdw xmm3, xmm9 ; xmm3 = [ 0 | 0 | 0 | 0 | 0 | 0 | bS (si b1 > uS) | bS (si b0 > uS) ]
        packusdw xmm0, xmm9 ; xmm0 = [ 0 | 0 | 0 | 0 | 0 | 0 | bI (si b1 > uI) | bI (si b0 > uI) ]
 
        ; /////////////////////////////////////////////////////////////////////////////////////////////////////////////

        pmovzxbw xmm1, xmm1 ; xmm1 = [ A1 | R1 | G1 | B1 | A0 | R0 | G0 | B0 ]

        ; /////////////////////////////////////////////////////////////////////////////////////////////////////////////

        pshuflw xmm6, xmm3, 0xC0    ; xmm6 = [ kk |   kk   |   kk   |   kk   | 00 | bS(p0) | bS(p0) | bS(p0) ]

        pslldq xmm3, 8              ; xmm3 = [ 00 |   00   | bS(p1) ] bS(p0) | 00 |   00   |   00   |   00   ]
        
        pshufhw xmm7, xmm3, 0xD5    ; xmm7 = [ 00 | bS(p1) | bS(p1) | bS(p1) | 00 |   kk   |   kk   |   kk   ]

        por xmm6, xmm7

        paddusw xmm1, xmm6
        
        ; /////////////////////////////////////////////////////////////////////////////////////////////////////////////

        pshuflw xmm6, xmm0, 0xC0    ; xmm6 = [ 00 |   00   |   00   |   00   | 00 | bI(p0) | bI(p0) | bI(p0) ]
        
        pslldq xmm0, 8              ; xmm0 = [ 00 |   00   | bI(p1) ] bI(p0) | 00 |   00   |   00   |   00   ]
        
        pshufhw xmm7, xmm0, 0xD5    ; xmm7 = [ 00 | bI(p1) | bI(p1) | bI(p1) | 00 |   00   |   00   |   00   ]

        por xmm6, xmm7

        psubusw xmm1, xmm6

        packuswb xmm1, xmm9

        movq [rsi], xmm1

        add rsi, 8
        add rdi, 8
        sub rax, 8
        jmp .ciclo_brillos

    .fin:
    pop rbp
ret
