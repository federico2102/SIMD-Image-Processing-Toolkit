; void ondas_asm (
; 	unsigned char *src,
; 	unsigned char *dst,
; 	int width,
; 	int height,
; 	int src_row_size,
;   int dst_row_size,
;	int x0,
;	int y0
; );

; Parámetros:
; 	rdi = src
; 	rsi = dst
; 	rdx = width
; 	rcx = height
; 	r8 = src_row_size
; 	r9 = dst_row_size
;   rbp + 16 = x0
; 	rbp + 24 = y0

section .data
DEFAULT REL

section .rodata 
PI: 						dd 3.1415, 3.1415, 3.1415, 3.1415
RADIUS: 					dd 35.0, 35.0, 35.0, 35.0
WAVELENGTH: 				dd 64.0, 64.0, 64.0, 64.0
TRAINWIDTH: 				dd 3.4, 3.4, 3.4, 3.4
UNOS: 						dd 1.0, 1.0, 1.0, 1.0
SEIS: 						dd 6.0, 6.0, 6.0, 6.0
CIENTOVEINTE: 				dd 120.0, 120.0, 120.0, 120.0
CINCOMILCUARENTA: 			dd 5040.0, 5040.0, 5040.0, 5040.0
SESENTAYCUATRO: 			dd 64.0, 64.0, 64.0, 64.0
DOSCIENTOSCINCUENTAYCINCO: 	dd 255.0, 255.0, 255.0, 255.0
sinA:						dd 0xff, 0xff, 0xff, 0x00
soloA: 						dd 0x00, 0x00, 0x00, 0xff

extern ondas_c

global ondas_asm

section .text

ondas_asm:
	;; TODO: Implementar

	push rbp
	mov rbp, rsp
	sub rsp, 8
	push rbx
	push r12
	push r13
	push r14
	push r15

	mov rbx, rdi 	;rbx -> *src
	mov r12, rsi	;r12 -> *dst
	mov r13, rdx	;r13 -> w
	mov r14, rcx	;r14 -> h

	xor r9, r9		;r9 -> recorro columnas (x)
	xor r10, r10	;r10 -> recorro filas (y)
	xor r11, r11 	;r11 -> recorro toda la matriz
	movdqu xmm9, [SESENTAYCUATRO]
	xorps xmm11, xmm11
	cvtdq2ps xmm11, xmm11
	movdqu xmm12, [DOSCIENTOSCINCUENTAYCINCO]
	xor rax, rax

	.ciclo:

	cmp r9, r13
	je .actualizarAnchoYAlto

	xorps xmm10, xmm10
	movd xmm10, [rbx+r11]
	punpcklbw xmm10, xmm11
	punpcklwd xmm10, xmm11
	movdqu xmm13, xmm10
	cvtdq2ps xmm10, xmm10		;xmm10 -> un pixel donde cada componente ocupa 32 bits

	movdqu xmm14, [soloA]
	pand xmm13, xmm14
	movdqu xmm14, [sinA]

	xorps xmm0, xmm0 
	mov rdi, r10
	mov rsi, r9
	mov rdx, [rbp+16]
	mov rcx, [rbp+24]
	call profundidad_asm

	mulps xmm0, xmm9
	addps xmm10, xmm0
	maxps xmm10, xmm11
	minps xmm10, xmm12

	cvtps2dq xmm10, xmm10
	pand xmm10, xmm14
	paddd xmm10, xmm13
	packusdw xmm10, xmm11
	packuswb xmm10, xmm11	;Empaqueto el pixel modificado para que vuelva a ocupar una dw
	movd [r12+r11], xmm10	;Muevo el pixel resultante a la imagen destino

	add r11, 4
	inc r9
	jmp .ciclo

	.actualizarAnchoYAlto:
	xor r9, r9
	inc r10
	cmp r10, r14
	je .fin
	jmp .ciclo

	.fin:
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbx
	add rsp, 8
	pop rbp

	ret

global profundidad_asm

profundidad_asm:

	sub rsp, 8

	cvtsi2ss xmm1, rdi
	pshufd xmm1, xmm1, 0x00		;xmm1 -> [y | y | y | y]

	cvtsi2ss xmm2, rsi
	pshufd xmm2, xmm2, 0x00		;xmm2 -> [x | x | x | x]

	cvtsi2ss xmm3, rdx
	pshufd xmm3, xmm3, 0x00		;xmm3 -> [x0 | x0 | x0 | x0]

	cvtsi2ss xmm4, rcx
	pshufd xmm4, xmm4, 0x00		;xmm4 -> [y0 | y0 | y0 | y0]

	;CALCULO Dx
	subps xmm2, xmm3 			;xmm2 -> [x-x0 | x-x0 | x-x0 | x-x0] = [dx | dx | dx | dx]

	;CALCULO Dy
	subps xmm1, xmm4			;xmm1 -> [y-y0 | y-y0 | y-y0 | y-y0]

	;CALCULO Dxy
	mulps xmm2, xmm2
	mulps xmm1, xmm1
	addps xmm1, xmm2
	sqrtps xmm1, xmm1			;xmm1 -> [sqrt(dx*dx+dy*dy) | sqrt(dx*dx+d[y+1]*d[y+1]) | sqrt(dx*dx+d[y+2]*d[y+2]) | sqrt(dx*dx+d[y+3]*d[y+3])]

	;CALCULO r
	movdqu xmm2, [RADIUS]
	subps xmm1, xmm2
	movdqu xmm3, [WAVELENGTH]
	divps xmm1, xmm3			;xmm1 -> r

	;CALCULO k
	movdqu xmm2, xmm1
	movdqu xmm3, xmm1
	roundps xmm3, xmm3, 01b
	subps xmm2, xmm3		;xmm2 -> k

	;CALCULO a
	movdqu xmm3, xmm1
	movdqu xmm4, [TRAINWIDTH]
	divps xmm3, xmm4
	mulps xmm3, xmm3
	movdqu xmm4, [UNOS]
	addps xmm3, xmm4
	divps xmm4, xmm3
	movdqu xmm3, xmm4 			;xmm3 -> a

	;CALCULO t
	movdqu xmm4, xmm2
	addps xmm4, xmm4
	movdqu xmm5, [PI]
	mulps xmm4, xmm5
	subps xmm4, xmm5
	movdqu xmm0, xmm4 			;xmm0 -> t

	;CALCULO s_taylor
	call sin_taylor_asm

	;CALCULO RESULTADO A RETORNAR (a*s_taylor) 	
	mulps xmm0, xmm3		

	add rsp, 8

	ret

global sin_taylor_asm

sin_taylor_asm:
	
	sub rsp, 8

	movdqu xmm4, xmm0
	movdqu xmm5, xmm0
	movdqu xmm6, xmm0

	mulps xmm4, xmm4
	mulps xmm4, xmm0 	;xmm4 -> x*x*x

	mulps xmm5, xmm4
	mulps xmm5, xmm0 	;xmm5 -> x*x*x*x*x

	mulps xmm6, xmm5
	mulps xmm6, xmm0 	;xmm6 -> x*x*x*x*x*x*x
	
	movdqu xmm7, [CIENTOVEINTE]
	divps xmm5, xmm7	;xmm5 -> x_5/120
	
	movdqu xmm7, [SEIS]
	divps xmm4, xmm7	;xmm4 -> x_3/6
	
	movdqu xmm7, [CINCOMILCUARENTA]
	divps xmm6, xmm7	;xmm6 -> x_7/5040

	subps xmm0, xmm4
	addps xmm0, xmm5
	subps xmm0, xmm6

	add rsp, 8

	ret
