; void monocromatizar_inf_asm (
; 	unsigned char *src,
; 	unsigned char *dst,
; 	int width,
; 	int height,
; 	int src_row_size,
; 	int dst_row_size
; );

; Parámetros:
; 	rdi = src
; 	rsi = dst
; 	rdx = width
; 	rcx = height
; 	r8 = src_row_size
; 	r9 = dst_row_size

extern monocromatizar_inf_c

global monocromatizar_inf_asm

section .data
DEFAULT REL

section .rodata

; CONSULTAR SI ESTAN BIEN DECLARADAS LAS MASRCARAS
mascara_A: dd 0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000
mascara_NOT_A: dd 0x00FFFFFF, 0x00FFFFFF, 0x00FFFFFF, 0x00FFFFFF

section .text

monocromatizar_inf_asm:

	; call monocromatizar_inf_c
	push rbp ; Alineada
	mov rbp, rsp
	push rbx ; Desalineada
	push r11 ; Alineada
	push r12 ; Desalineada
	push r13 ; Alineada
	push r14 ; Desalineada
	push r15 ; Alineada

	;copio los parametros de entrada
	mov rbx, rdi ;rbx = src
	mov r12, rdx ;r12 = width
	mov r13, rcx ;r13 = height
	mov r14, rsi ;r14 = dst
	mov r15, r9 ;r15 = dst_row_size
	mov r11, r8 ; r11 = src_row_size
	
	movdqu xmm10, [mascara_A]
	movdqu xmm11, [mascara_NOT_A]

	mov rsi, r13
	imul rsi, rdx ;multiplico ancho y alto de la imagen para saber cuantos pixeles tiene.
	sar rsi, 2 ;divido el numero de pixeles por cuatro por que los voy a trabajar de a cuatro
	mov rcx, rsi
	mov rdx, r14 ;uso rdx para armar la imagen

.ciclo:
	movdqu xmm0, [rdi] ;agarro cuatro pixeles de la imagen
	movdqu xmm8, xmm0;voy a utilizar xmm8 para almacenar el resultado de las cuentas sobre las componentes
	
	;como la componente A tiene que quedar igual, realizo un and entre xmm8 y la mascaraA, que deja solo los bits de la componente A en xmm8
	pand xmm8, xmm10  ;xmm8 = [Pixel 1 = A | 0 | 0 | 0, Pixel 2 = A | 0 | 0 | 0, Pixel 3 = A | 0 | 0 | 0, Pixel 4 = A | 0 | 0 | 0 ]
	
	movdqu xmm2, xmm0 ;copio los pixeles para poder desempaquetar las componentes de byte a word
	pxor xmm5, xmm5 ;limpio xmm5 para usarlo para desempaquetar
	punpcklbw xmm0, xmm5 ;xmm0 = [Pixel 1 = A | R | G | B, Pixel 2 = A | R | G | B]
	punpckhbw xmm2, xmm5  ;xmm2 = [Pixel 3 = A | R | G | B, Pixel 4 = A | R | G | B]
	
	CVTDQ2PS xmm0, xmm0
	; cvttps2dq xmm0, xmm0

	movdqu xmm1, xmm0 ;xmm1 = [Pixel 1 = A | R | G | B, Pixel 2 = A | R | G | B]
	; CONSULTAR LOS SHIFTS; SI LO HAGO DE A WORD, ESTA BIEN EL 16?
	psllq xmm1, 16 ;xmm1 = [Pixel 1 = R | G | B | 0, Pixel 2 = R | G | B | 0]
	maxps xmm0, xmm1 ; xmm0 = [Pixel 1 = max(A,R) | max(R,G) | max(G,B) | max(B,0), Pixel 2 = max(A,R) | max(R,G) | max(G,B) | max(B,0)]
	psllq xmm1, 16 ;xmm1 = [Pixel 1 = G | B | 0 | 0, Pixel 2 = G | B | 0 | 0]
	maxps xmm0, xmm1 ; xmm0 = [Pixel 1 = max(A,R,G) | max(R,G,B) | max(G,B,0) | max(B,0,0), Pixel 2 = max(A,R,G) | max(R,G,B) | max(G,B,0) | max(B,0,0)]
	
	CVTPS2DQ xmm0, xmm0
	; CONSULTAR LA PARTE DEL SHUFFLE
	pshufhw xmm7, xmm0, 0b10101010 ; CONSULTAR ESTO - MI IDEA ES PONER MAX(R,G,B) EN CADA COMPONENTE DEL PIXEL
	pshuflw xmm7, xmm7, 0b10101010
	
	CVTDQ2PS xmm2, xmm2
	movdqu xmm3, xmm2 ;xmm3 = [Pixel 3 = A | R | G | B, Pixel 4 = A | R | G | B]
	psllq xmm3, 16 ;xmm3 = [Pixel 1 = R | G | B | 0, Pixel 2 = R | G | B | 0]
	; maxps xmm2, xmm3 ; xmm2 = [Pixel 1 = max(A,R) | max(R,G) | max(G,B) | max(B,0), Pixel 2 = max(A,R) | max(R,G) | max(G,B) | max(B,0)]
	maxps xmm2, xmm3 ; xmm2 = [Pixel 1 = max(A,R) | max(R,G) | max(G,B) | max(B,0), Pixel 2 = max(A,R) | max(R,G) | max(G,B) | max(B,0)]
	psllq xmm3, 16 ;xmm3 = [Pixel 1 = G | B | 0 | 0, Pixel 2 = G | B | 0 | 0]
	maxps xmm2, xmm3 ; xmm2 = [Pixel 1 = max(A,R,G) | max(R,G,B) | max(G,B,0) | max(B,0,0), Pixel 2 = max(A,R,G) | max(R,G,B) | max(G,B,0) | max(B,0,0)]
	; maxps xmm2, xmm3 ; xmm2 = [Pixel 1 = max(A,R,G) | max(R,G,B) | max(G,B,0) | max(B,0,0), Pixel 2 = max(A,R,G) | max(R,G,B) | max(G,B,0) | max(B,0,0)]

	CVTPS2DQ xmm2, xmm2
	; CONSULTAR LA PARTE DEL SHUFFLE
	pshufhw xmm9, xmm2, 0b10101010 ; CONSULTAR ESTO - MI IDEA ES PONER MAX(R,G,B) EN CADA COMPONENTE DEL PIXEL
	pshuflw xmm9, xmm9, 0b10101010


	
	; CONSULTAR SI ESTOY RESTAURANDO BIEN LOS A
	PACKUSWB xmm7, xmm9
	
	; NUEVO
	pand xmm7, xmm11 ;xmm8 = [Pixel 1 = 0 | max(R,G,B) | max(R,G,B) | max(R,G,B), Pixel 2 = 0 | max(R,G,B) | max(R,G,B) | max(R,G,B), Pixel 3 = 0 | max(R,G,B) | max(R,G,B) | max(R,G,B), Pixel 4 = 0 | max(R,G,B) | max(R,G,B) | max(R,G,B) ]
	por xmm7, xmm8 ;xmm7 = [Pixel 1 = A | max(R,G,B) | max(R,G,B) | max(R,G,B), Pixel 2 = A | max(R,G,B) | max(R,G,B) | max(R,G,B), Pixel 3 = A | max(R,G,B) | max(R,G,B) | max(R,G,B), Pixel 4 = A | max(R,G,B) | max(R,G,B) | max(R,G,B) ]

	movdqu [rdx], xmm7
	lea rdi, [rdi + 16]
	lea rdx, [rdx + 16]
	dec rcx
	cmp rcx, 0
	jne .ciclo

	pop r11
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbx
	pop rbp

ret
