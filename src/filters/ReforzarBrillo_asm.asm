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
    mov rbp, rsp        ; StackFrame

    movaps xmm1, [extiende_y_copia_green_alto]
    movaps xmm0, [extiende_y_copia_green_bajo]

    movups xmm2, [rdi]  ; xmm1 = [ a_3 | r_3 | g_3 | b_3 | ... ]
    movaps xmm3, xmm2
    movaps xmm4, xmm2
    
    xor xmm5, xmm5

    pshufb xmm3, xmm0   ; xmm3 = [ pixel 1 | pixel 0 ] y con el formato [ G | R | G | B ] para facilitar la suma
    pshufb xmm4, xmm1   ; xmm4 = [ pixel 3 | pixel 2 ] con el mismo formato
    
    phaddw xmm3, xmm5   ; xmm3 = [ 0 | 0 | 0 | 0 | G + R (pixel1) | G + B (pixel1) | G + R (pixel0) | G + B (pixel0) ]
    phaddw xmm4, xmm5   ; xmm4 = [ 0 | 0 | 0 | 0 | G + R (pixel3) | G + B (pixel2) | G + R (pixel3) | G + B (pixel2) ]

    phaddw xmm3, xmm5   ; xmm3 = [ 0 | 0 | 0 | 0 | R + 2G + B (pixel1) | R + 2G + B (pixel0) | R + 2G + B (pixel1) | R + 2G + B (pixel0) ]
    phaddw xmm4, xmm5   ; xmm4 = [ 0 | 0 | 0 | 0 | R + 2G + B (pixel3) | R + 2G + B (pixel2) | R + 2G + B (pixel3) | R + 2G + B (pixel2) ]
    
    psrldq xmm3, 4
    psrldq xmm4, 4

    pslldq xmm4, 4
    por xmm3, xmm4      ; xmm3 = [ 0 | 0 | 0 | 0 | R + 2G + B (pixel3) | R + 2G + B (pixel2) | R + 2G + B (pixel1) | R + 2G + B (pixel0) ]

    psrlw xmm4, 2       ; xmm3 = [ 0 | 0 | 0 | 0 | (R + 2G + B)/4 (pixel3) | (R + 2G + B)/4 (pixel2) | (R + 2G + B)/4 (pixel1) | (R + 2G + B)/4 (pixel0) ]
    movdqa xmm3, xmm4   ; copias para facilitar
    movdqa xmm2, xmm4   ; la cantidad 
    
ret
