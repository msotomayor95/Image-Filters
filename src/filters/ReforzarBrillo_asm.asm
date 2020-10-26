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
    ; rdx = width 
    ; rcx = height
    ; r8 = src_row_size
    ; r9 = dst_row_size
    ; [rbp+16] = umbralSup
    ; [rbp+24] = umbralInf
    ; [rbp+32] = brilloSup
    ; [rsp+40] = brilloInf

    push rbp
    mov rbp, rsp    ; StackFrame

    ; movaps xmm15, [extiende_y_copia_green_alto]
    movaps xmm14, [extiende_y_copia_green_bajo]

    pxor xmm9, xmm9

    movd xmm13, [rbp + 16]      ; Muevo umbralSup a la parte baja xmm13
    pshufd xmm13, xmm13, 0x00   ; [ umbralSup | umbralSup | umbralSup | umbralSup ]

    movd xmm12, [rbp + 24]      ; Muevo umbralInf a la parte baja de xmm12
    pshufd xmm12, xmm12, 0x00   ; [ umbralInf | umbralInf | umbralInf | umbralInf ]

    movd xmm11, [rbp + 32]      ; Muevo umbralSup a la parte baja de xmm11
    pshufd xmm11, xmm11, 0x00   ; [ brilloSup | brilloSup | brilloSup | brilloSup ]

    movd xmm10, [rbp + 40]      ; Muevo umbralInf a la parte baja de xmm10
    pshufd xmm10, xmm10, 0x00   ; [ brilloInf | brilloInf | brilloInf | brilloInf ]
    
    packusdw xmm13, xmm9        ; [ 0 | 0 | 0 | 0 | umbralSup | umbralSup | umbralSup | umbralSup ]
    packusdw xmm12, xmm9        ; [ 0 | 0 | 0 | 0 | umbralInf | umbralInf | umbralInf | umbralInf ]

    movdqu xmm1, [rdi]  ; xmm1 = [ a_3 | r_3 | g_3 | b_3 | ... ]
    movdqa xmm2, xmm1
    movdqa xmm3, xmm1  
    

    pshufb xmm2, xmm14  ; xmm3 = [ pixel 1 | pixel 0 ] y con el formato [ G | R | G | B ] para facilitar la suma
    
    phaddw xmm3, xmm9   ; xmm3 = [ 0 | 0 | 0 | 0 | G + R (pixel1) | G + B (pixel1) | G + R (pixel0) | G + B (pixel0) ]

    phaddw xmm3, xmm4   ; xmm3 = [ 0 | 0 | 0 | 0 | R + 2G + B (pixel1) | R + 2G + B (pixel0) | R + 2G + B (pixel1) | R + 2G + B (pixel0) ]
    
    psrldq xmm3, 4      ; xmm3 = [ 0 | 0 | 0 | 0 | 0 | 0 | R + 2G + B (pixel1) | R + 2G + B (pixel0) ]

    psrlw xmm3, 2       ; xmm3 = [ 0 | 0 | 0 | 0 | 0 | 0 | (R + 2G + B)/4 (pixel1) | (R + 2G + B)/4 (pixel0) ]

    
ret
