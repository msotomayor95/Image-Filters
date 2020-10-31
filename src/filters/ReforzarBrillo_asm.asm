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

    movaps xmm15, [extiende_y_copia_green_bajo]

    pxor xmm9, xmm9

    movd xmm14, [rbp + 16]      ; Muevo umbralSup a la parte baja xmm13
    pshufd xmm14, xmm14, 0x00   ; [ umbralSup | umbralSup | umbralSup | umbralSup ]

    movd xmm13, [rbp + 24]      ; Muevo umbralInf a la parte baja de xmm12
    pshufd xmm13, xmm13, 0x00   ; [ umbralInf | umbralInf | umbralInf | umbralInf ]

    movd xmm12, [rbp + 32]      ; Muevo umbralSup a la parte baja de xmm11
    pshufd xmm12, xmm12, 0x00   ; [ brilloSup | brilloSup | brilloSup | brilloSup ]

    movd xmm11, [rbp + 40]      ; Muevo umbralInf a la parte baja de xmm10
    pshufd xmm11, xmm11, 0x00   ; [ brilloInf | brilloInf | brilloInf | brilloInf ]
    
    ; packusdw xmm14, xmm9        
    ; psrldq xmm14, 4             ; [ 0 | 0 | 0 | 0 | 0 | 0 | umbralSup | umbralSup ]

    ; packusdw xmm13, xmm9        
    ; psrldq xmm13, 4             ; [ 0 | 0 | 0 | 0 | 0 | 0 | umbralInf | umbralInf ]

    ; packusdw xmm12, xmm9        
    ; psrldq xmm12, 4             ; [ 0 | 0 | 0 | 0 | 0 | 0 | brilloSup | brilloSup ]
    
    ; packusdw xmm11, xmm9        
    ; psrldq xmm11, 4             ; [ 0 | 0 | 0 | 0 | 0 | 0 | brilloSup | brilloSup ]

    xor rdx, rdx
    mov eax, r8d 
    mul ecx
    shl rdx, 32
    or rax, rdx
    add rax, rsi
    
    .ciclo_brillos:
        cmp rax, rsi
        je .fin

        movdqu xmm0, [rdi]  ; xmm0 = [ a_3 | r_3 | g_3 | b_3 | ... ]
        movdqa xmm1, xmm0
        
        pshufb xmm0, xmm15  ; xmm0 = [ pixel 1 | pixel 0 ] y con el formato [ G | R | G | B ] para facilitar la suma
        
        ; ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

        phaddw xmm0, xmm9   ; xmm0 = [ 0 | 0 | 0 | 0 | G + R (pixel1) | G + B (pixel1) | G + R (pixel0) | G + B (pixel0) ]

        phaddw xmm0, xmm9   ; xmm0 = [ 0 | 0 | 0 | 0 | 0 | 0 | R + 2G + B (pixel1) | R + 2G + B (pixel0) ]

        psrlw xmm0, 2           ; xmm0 = [ 0 | 0 | 0  | 0  | 0  | 0  | (R + 2G + B)/4 (b de pixel1) | (R + 2G + B)/4 (b de pixel0) ]
        punpcklwd xmm0, xmm9    ; xmm0 = [ 0 | 0 | B1 | B2 ]
        movdqa xmm3, xmm0       ; copia

        pmaxuw xmm0, xmm13  ; xmm0 = [ 0 | 0 | max(b1, umbralInf) | max(b0, umbralInf) ]        
        pcmpeqw xmm0, xmm13 ; me quedan todos 1s donde b < umbralInf

        pminuw xmm3, xmm14  ; xmm3 = [ 0 | 0 | min(b1, umbralSup) | min(b0, umbralSup) ]
        pcmpeqw xmm3, xmm14 ; me quedan todos 1s donde b > umbralInf   

        pand xmm3, xmm11    
        pslldq xmm3, 8
        psrldq xmm3, 8      ; xmm3 = [ 0 | 0 | brillSup (si b1 > uS) | brilloSup (si b0 > uS) ]

        pand xmm0, xmm12    
        pslldq xmm0, 8
        psrldq xmm0, 8      ; xmm0 = [ 0 | 0 | brillInf (si b1 < uI) | brilloInf (si b0 < uI) ]

        packusdw xmm3, xmm9
        packusdw xmm0, xmm9
 
        ; /////////////////////////////////////////////////////////////////////////////////////////////////////////////

        punpcklbw xmm1, xmm9        ; xmm1 = [ A1 | R1 | G1 | B1 | A0 | R0 | G0 | B0 ]

        ; /////////////////////////////////////////////////////////////////////////////////////////////////////////////

        pshuflw xmm6, xmm3, 0xC0    ; xmm6 = [ kk | kk | kk | kk | 00 | bS | bS | bS ]
        pslldq xmm3, 4
        pshufhw xmm6, xmm3, 0xD5    ; xmm6 = [ 00 | bS | bS | bS | 00 | bS | bS | bS ]

        paddusw xmm1, xmm6
        
        ; /////////////////////////////////////////////////////////////////////////////////////////////////////////////

        pshuflw xmm6, xmm0, 0xC0    ; xmm6 = [ kk | kk | kk | kk | 00 | bI | bI | bI ]
        pslldq xmm0, 4
        pshufhw xmm6, xmm0, 0xD5    ; xmm6 = [ 00 | bI | bI | bI | 00 | bI | bI | bI ]

        psubusw xmm1, xmm0

        packuswb xmm1, xmm9

        movq [rsi], xmm1

        lea rsi, [rsi + 8]
        lea rdi, [rdi + 8]
        jmp .ciclo_brillos

    .fin:
    pop rbp
ret
