extern ReforzarBrillo_c
global ReforzarBrillo_asm

section .rodata
    align 16
	; ceros = 80 green1 = 05 ceros = 80 red1 = 06 ceros = 80 green1 = 05 ceros = 80 blue1 = 04 ceros = 80 green = 01 ceros = 80 red = 02 ceros = 80 green = 01 ceros = 80 blue0 = 00
	extiende_y_copia_green_bajo: DQ 0x8001800280018000, 0x8005800680058004
	extiende_y_copia_green_alto: DQ 0x8009800A80098008, 0x800D800E800D800C

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

    movaps xmm15, [extiende_y_copia_green_alto]
    movaps xmm14, [extiende_y_copia_green_bajo]

    pxor xmm13, xmm13
    movd xmm13, [rbp + 16]      ; Muevo umbralSup a la parte baja xmm13
    pshufd xmm13, xmm13, 0x00   ; [ umbralSup | umbralSup | umbralSup | umbralSup ]

    pxor xmm12, xmm12
    movd xmm12, [rbp + 24]      ; Muevo umbralInf a la parte baja de xmm12
    pshufd xmm12, xmm12, 0x00   ; [ umbralInf | umbralInf | umbralInf | umbralInf ]


    movups xmm2, [rdi]  ; xmm1 = [ a_3 | r_3 | g_3 | b_3 | ... ]
    movaps xmm3, xmm1
    
    xor xmm4, xmm4

    pshufb xmm2, xmm14  ; xmm3 = [ pixel 1 | pixel 0 ] y con el formato [ G | R | G | B ] para facilitar la suma
    pshufb xmm3, xmm15  ; xmm4 = [ pixel 3 | pixel 2 ] con el mismo formato
    
    phaddw xmm3, xmm4   ; xmm3 = [ 0 | 0 | 0 | 0 | G + R (pixel1) | G + B (pixel1) | G + R (pixel0) | G + B (pixel0) ]
    phaddw xmm4, xmm4   ; xmm4 = [ 0 | 0 | 0 | 0 | G + R (pixel3) | G + B (pixel2) | G + R (pixel3) | G + B (pixel2) ]

    phaddw xmm3, xmm4   ; xmm3 = [ 0 | 0 | 0 | 0 | R + 2G + B (pixel1) | R + 2G + B (pixel0) | R + 2G + B (pixel1) | R + 2G + B (pixel0) ]
    phaddw xmm4, xmm4   ; xmm4 = [ 0 | 0 | 0 | 0 | R + 2G + B (pixel3) | R + 2G + B (pixel2) | R + 2G + B (pixel3) | R + 2G + B (pixel2) ]
    
    psrldq xmm3, 4
    psrldq xmm4, 4

    pslldq xmm4, 4
    por xmm3, xmm4      ; xmm3 = [ 0 | 0 | 0 | 0 | R + 2G + B (pixel3) | R + 2G + B (pixel2) | R + 2G + B (pixel1) | R + 2G + B (pixel0) ]

    psrlw xmm3, 2       ; xmm3 = [ 0 | 0 | 0 | 0 | (R + 2G + B)/4 (pixel3) | (R + 2G + B)/4 (pixel2) | (R + 2G + B)/4 (pixel1) | (R + 2G + B)/4 (pixel0) ]
    
    pmovzxwd xmm3, xmm3 ; xmm3 = [ (R + 2G + B)/4 (pixel3) | (R + 2G + B)/4 (pixel2) | (R + 2G + B)/4 (pixel1) | (R + 2G + B)/4 (pixel0) ]
    movdqa xmm4, xmm3   ; copia. Ahora a la cuenta la llamare b

    pcmpgtd xmm3, xmm13 ; xmm3 = [ b > umbralSup (pixel3) | b > umbralSup (pixel2) | b > umbralSup (pixel1) | b > umbralSup (pixel0) ]
    movdqa xmm5, xmm3   ; copia

    pandn xmm5, xmm4    ; tomo los b que no cumpliero con la condicion
    movdqa xmm6, xmm12
    pcmpgtd xmm6, xmm5  ; xmm6 = [ b > umbralSup (pixel3) | b > umbralSup (pixel2) | b > umbralSup (pixel1) | b > umbralSup (pixel0) ]



    

    ; movdqa xmm5, xmm12
    ; pcmpgtd xmm5, xmm4  ; xmm5 = [ umbralInf > (R + 2G + B)/4 (pixel3) | umbralInf > (R + 2G + B)/4 (pixel2) | umbralInf > (R + 2G + B)/4 (pixel1) | umbralInf > (R + 2G + B)/4 (pixel0) ]

    
ret
