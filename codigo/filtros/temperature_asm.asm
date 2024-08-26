; void temperature_asm (
;   unsigned char *src,
;   unsigned char *dst,
;   int width,
;   int height,
;   int src_row_size,
;   int dst_row_size
; );

; Parámetros:
; 	rdi = src
; 	rsi = dst
; 	rdx = width
; 	rcx = height
; 	r8 = src_row_size
; 	r9 = dst_row_size

section .data
DEFAULT REL

section .rodata

shuffle: db 0x00, 0x04, 0x08, 0x0C, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
repeat:  dd 0xFF000000, 0xFF010101, 0xFF020202, 0xFF030303 
divisor: times 4  dd 3.0
unsign:  times 16 db 0x80
ones:    times 16 db 0xFF

val31: 	 times 16 db -97	;  31 - 128 = -97
val95:   times 16 db -33	;  95 - 128 = -33
val159:  times 16 db 0x1F	; 159 - 128 = 31
val223:  times 16 db 0x5F	; 223 - 128 = 95

val32: 	 times 16 db 0x20
val96: 	 times 16 db 0x60
val128:  times 16 db 0x80
val160:  times 16 db 0xA0
val224:  times 16 db 0xE0
val255:  times 16 db 0xFF

; val31:   times 16 db 0x1F
; val95:   times 16 db 0x5F
; val159:  times 16 db 0x9F
; val223:  times 16 db 0xDF

; b|g|r|a => a|r|g|b
a:   times 4 dd 0xFF000000
r:   times 4 dd 0x00FF0000
g:   times 4 dd 0x0000FF00
b:   times 4 dd 0x000000FF


section .text
global temperature_asm

temperature_asm:
	push rbp ; Alineada
	mov  rbp, rsp
	push rbx ; Desalineada
	push r11 ; Alineada
	push r12 ; Desalineada
	push r13 ; Alineada
	push r14 ; Desalineada
	push r15 ; Alineada

	; Copio los parametros de entrada
	mov rbx, rdi		; rbx = src
	mov r12, rdx		; r12 = width
	mov r13, rcx		; r13 = height
	mov r14, rsi		; r14 = dst
	mov r15, r9			; r15 = dst_row_size
	mov r11, r8			; r11 = src_row_size

	mov  rsi, r13
	imul rsi, rdx 		; multiplico ancho y alto de la imagen para saber cuantos pixeles tiene.
	sar  rsi, 2 		; divido el numero de pixeles por cuatro por que los voy a trabajar de a cuatro
	mov  rcx, rsi
	mov  rdx, r14 		; uso rdx para armar la imagen
	
	movdqu xmm7,  [a]				; alphas iguales a 1
	movdqu xmm8,  [ones]
	movdqu xmm9,  [unsign]			; mascara para pasar a numeros con signo
	movdqu xmm10, [shuffle]			; mascara para reordenar los bytes
	movdqu xmm11, [divisor]			; divisor
	movdqu xmm12, [repeat]			; mascara para repetr los t
	movdqu xmm13, [r]				; mascara para dejar solo los rojos
	movdqu xmm14, [g]				; mascara para dejar solo los verdes
	movdqu xmm15, [b]				; mascara para dejar solo los azules


.ciclo:
	movdqu    xmm0, [rdi]			; xmm0 = b|g|r|a|b|g|r|a| ... (leo 16 bytes)

	movdqu    xmm1, xmm0
	psrldq    xmm1, 1				; xmm2 = g|r|a|b|g|r|a|b| ...
	movdqu    xmm2, xmm0
	psrldq    xmm2, 2				; xmm2 = r|a|b|g|r|a|b|g| ...

	pshufb    xmm0, xmm10			; xmm0 = b|b|b|b|x ... x (4 azules leidos)
	pshufb    xmm1, xmm10			; xmm1 = g|g|g|g|x ... x (4 verdes leidos)
	pshufb    xmm2, xmm10			; xmm2 = r|r|r|r|x ... x (4 rojos leidos)

	pxor      xmm3, xmm3
	punpcklbw xmm0, xmm3			; desenpaqueto los bytes a words, me quedo con la parte baja
	punpcklbw xmm1, xmm3
	punpcklbw xmm2, xmm3

	paddw     xmm0, xmm1			; xmm0 = b + g
	paddw     xmm0, xmm2			; xmm0 = b + g + r

	punpcklwd xmm0, xmm3			; desenpaqueto de word a double
	cvtdq2ps  xmm0, xmm0			; convierto los enteros a floats
	divps     xmm0, xmm11			; divido por 3

	cvttps2dq xmm0, xmm0			; convierto a entero por truncado
									; xmm0 = t | t | t | t
	packusdw  xmm0, xmm3			; Paso a word. xmm0 = 4 veces t|0
	packuswb  xmm0, xmm3			; Paso a byte. xmm0 = 4 veces t|0|0|0
	pshufb    xmm0, xmm12			; xmm0 = t1|t1|t1|0 | t2|t2|t2|0 | t3|t3|t3|0 | t4|t4|t4|0

	movdqu    xmm1, xmm7			; Guardo el resultado. Comienzo con alhpas iguales a 1
	pxor	  xmm2, xmm2			; Guardo la mascara de y < t <= x


	; Comparacion t > 223 (t >= 224)
	movdqu  xmm2, xmm0
	movdqu  xmm3, [val223]
	pxor    xmm2, xmm9				; Paso a un valor con signo para comparar con signo
	pcmpgtb xmm2, xmm3				; xmm2 = mascara con 1 si t >= 224. Resto = 0
	
	; Rojo = 255 - (t - 224) * 4		
	movdqu  xmm4, xmm2
	pand    xmm4, xmm13				; xmm4 = mascara donde 1 = rojo y t >= 224
	movdqu  xmm3, xmm0
	pand    xmm3, xmm4				; xmm3 = t en rojos donde t >= 224. Resto = 0
	movdqu  xmm5, [val224]
	pand    xmm5, xmm4				; xmm5 = 224 en rojos donde t >= 224. Resto = 0
	psubd   xmm3, xmm5				; xmm3 = t - 224
	paddusb xmm3, xmm3				; xmm3 = (t - 224) * 2
	paddusb xmm3, xmm3				; xmm3 = (t - 224) * 4
	movdqu  xmm5, [val255]
	pand    xmm5, xmm4				; xmm5 = 255 en rojos donde t >= 224. Resto = 0
	psubd   xmm5, xmm3				; xmm5 = 255 - (t - 224) * 4
	por     xmm1, xmm5				; Guardo el resultado

	; Verde = 0
	; Azul = 0

	
	; Comparacion t > 159 (t >= 160)
	movdqu  xmm3, xmm0
	movdqu  xmm4, xmm2				; xmm4 = mascara con 1 si t >= 224. Resto = 0
	pxor    xmm4, xmm8				; Invierto la mascara => 0 si t >= 224, 1 sino
	pand    xmm3, xmm4				; xmm3 = t si t < 224. Resto = 0

	movdqu  xmm4, [val159]
	pxor    xmm3, xmm9
	pcmpgtb xmm3, xmm4				; xmm3 = mascara con 1 si 160 <= t < 224. Resto = 0
	por     xmm2, xmm3				; xmm2 = mascara con 1 si t >= 160. Resto = 0

	; Rojo = 255
	movdqu  xmm4, [val255]
	pand    xmm4, xmm3
	pand    xmm4, xmm13				; xmm4 = 255 en rojos donde 160 <= t < 224. Resto = 0
	por     xmm1, xmm4				; Guardo el resultado

	; Verde = 255 - (t - 160) * 4
	movdqu  xmm5, xmm3
	pand    xmm5, xmm14				; xmm5 = tiene 1 para los verdes donde 160 <= t < 224. Resto = 0
	movdqu  xmm4, xmm0
	pand    xmm4, xmm5				; xmm4 = verdes iguales a t si 160 <= t < 224. Resto = 0
	movdqu  xmm6, [val160]
	pand    xmm6, xmm5				; xmm6 = 160 en verdes donde 160 <= t < 224. Resto = 0
	psubd   xmm4, xmm6				; xmm4 = t - 160
	paddusb xmm4, xmm4				; xmm4 = (t - 160) * 2
	paddusb xmm4, xmm4				; xmm4 = (t - 160) * 4
	movdqu  xmm6, [val255]
	pand    xmm6, xmm5				; xmm6 = 255 en verdes donde 160 <= t < 224. Resto = 0
	psubusb xmm6, xmm4				; xmm6 = 255 - (t - 160) * 4
	por     xmm1, xmm6				; Guardo el resultado

	; Azul = 0

	
	; Comparacion t > 95 (t >= 96)
	movdqu  xmm3, xmm0
	movdqu  xmm4, xmm2				; xmm4 = mascara con 1 si t >= 160. Resto = 0
	pxor    xmm4, xmm8				; Invierto la mascara => 0 si t >= 160, 1 sino
	pand    xmm3, xmm4				; xmm3 = t si t < 160. Resto = 0

	movdqu  xmm4, [val95]
	pxor    xmm3, xmm9
	pcmpgtb xmm3, xmm4				; xmm3 = mascara con 1 si 96 <= t < 160. Resto = 0
	por     xmm2, xmm3				; xmm2 = mascara con 1 si t >= 96. Resto = 0

	; Rojo = (t - 96) * 4
	movdqu  xmm5, xmm3
	pand    xmm5, xmm13				; xmm5 = mascara con 1 para los rojos donde 96 <= t < 160. Resto = 0
	movdqu  xmm4, xmm0
	pand    xmm4, xmm5				; xmm4 = rojos iguales a t si 96 <= t < 160. Resto = 0
	movdqu  xmm6, [val96]
	pand    xmm6, xmm5				; xmm6 = 96 en rojos donde 96 <= t < 160. Resto = 0
	psubusb xmm4, xmm6				; xmm4 = t - 96
	paddusb xmm4, xmm4				; xmm4 = (t - 96) * 2
	paddusb xmm4, xmm4				; xmm4 = (t - 96) * 4
	por     xmm1, xmm4				; Guardo el resultado

	; Verde = 255
	movdqu  xmm4, [val255]
	pand    xmm4, xmm3
	pand    xmm4, xmm14				; xmm4 = 255 en verdes donde 96 <= t < 160. Resto = 0
	por     xmm1, xmm4				; Guardo el resultado

	; Azul = 255 - (t - 96) * 4
	movdqu  xmm5, xmm3
	pand    xmm5, xmm15				; xmm5 = mascara con 1 para los azules donde 96 <= t < 160. Resto = 0
	movdqu  xmm4, xmm0
	pand    xmm4, xmm5				; xmm4 = azules iguales a t si 96 <= t < 160. Cada pixel = 0|0|t|0
	movdqu  xmm6, [val96]
	pand    xmm6, xmm5				; xmm6 = 96 en azules donde 96 <= t < 160
	psubd   xmm4, xmm6				; xmm4 = t - 96
	paddusb xmm4, xmm4				; xmm4 = (t - 96) * 2
	paddusb xmm4, xmm4				; xmm4 = (t - 96) * 4
	movdqu  xmm6, [val255]
	pand    xmm6, xmm5				; xmm6 = 255 en azules donde 96 <= t < 160
	psubusb xmm6, xmm4				; xmm6 = 255 - (t - 96) * 4
	por     xmm1, xmm6				; Guardo el resultado


	; Comparacion t > 31 (t >= 32)
	movdqu  xmm3, xmm0
	movdqu  xmm4, xmm2				; xmm4 = mascara con 1 si t >= 96. Resto = 0
	pxor    xmm4, xmm8				; Invierto la mascara => 0 si t >= 96, 1 sino
	pand    xmm3, xmm4				; xmm3 = t si t < 96. Resto = 0

	movdqu  xmm4, [val31]
	pxor    xmm3, xmm9
	pcmpgtb xmm3, xmm4				; xmm3 = mascara con 1 si 32 <= t < 96. Resto = 0
	por     xmm2, xmm3				; xmm2 = mascara con 1 si t >= 32. Resto = 0

	; Rojo = 0

	; Verde = (t - 32) * 4
	movdqu  xmm5, xmm3
	pand    xmm5, xmm14				; xmm5 = mascara con 1 para los verdes donde 32 <= t < 96. Resto = 0
	movdqu  xmm4, xmm0
	pand    xmm4, xmm5				; xmm4 = verdes iguales a t si 32 <= t < 96. Cada pixel = 0|t|0|0
	movdqu  xmm6, [val32]
	pand    xmm6, xmm5				; xmm6 = 32 en rojos donde 32 <= t < 96
	psubusb xmm4, xmm6				; xmm4 = t - 32
	paddusb xmm4, xmm4				; xmm4 = (t - 32) * 2
	paddusb xmm4, xmm4				; xmm4 = (t - 32) * 4
	por     xmm1, xmm4				; Guardo el resultado

	; Azul = 255
	movdqu  xmm4, [val255]
	pand    xmm4, xmm3
	pand    xmm4, xmm15				; xmm3 = 255 en azules donde 32 <= t < 96
	por     xmm1, xmm4				; Guardo el resultado


	; Comparacion t >= 0
	pxor    xmm2, xmm8				; xmm2 = mascara con 1 si 0 <= t < 32. Resto = 0
	
	; Rojo = 0
	; Verde = 0

	; Azul = 128 + t * 4
	movdqu  xmm4, xmm2
	pand    xmm4, xmm15				; xmm4 = tiene 1 para los azules donde t < 32
	movdqu  xmm3, xmm0
	pand    xmm3, xmm4				; xmm3 = azules iguales a t si t < 32. Cada pixel = 0|0|t|0
	paddusb xmm3, xmm3				; xmm3 = t * 2
	paddusb xmm3, xmm3				; xmm3 = t * 4
	movdqu  xmm5, [val128]
	pand    xmm5, xmm4				; xmm2 = 128 en azules donde t < 32
	paddusb xmm5, xmm3				; xmm2 = 128 + t * 4
	por     xmm1, xmm5				; Guardo el resultado


	; Escribo en el destino
	movdqu [rdx], xmm1
	lea rdi, [rdi + 16]
	lea rdx, [rdx + 16]
	dec rcx
	cmp rcx, 0
	jne .ciclo


.fin:
	pop r11
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbx
	pop rbp
    ret
