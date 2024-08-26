; void edge_asm (
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

; Matriz de Laplace
; 0.5  1  0.5
;  1  -6   1
; 0.5  1  0.5

mascara_Laplace_centro_baja:   dw 0x0000, 0xffff, 0x0000, 0x0000, 0xffff, 0x0000, 0x0000, 0xffff
mascara_Laplace_centro_alta:   dw 0x0000, 0x0000, 0xffff, 0x0000, 0x0000, 0xffff, 0x0000, 0x0000
mascara_Laplace_extremos_baja: dw 0xffff, 0x0000, 0xffff, 0xffff, 0x0000, 0xffff, 0xffff, 0x0000
mascara_Laplace_extremos_alta: dw 0xffff, 0xffff, 0x0000, 0xffff, 0xffff, 0x0000, 0xffff, 0x0000
mascara_Laplace_seis_baja: 	   dw 0, -6,  0,  0, -6,  0,  0, -6
mascara_Laplace_seis_alta:     dw 0,  0, -6,  0,  0, -6,  0,  0

soloCentro:  db 0x00, 0xff, 0x00, 0x00, 0xff, 0x00, 0x00, 0xff, 0x00, 0x00, 0xff, 0x00, 0x00, 0xff, 0x00, 0x00
sinCentro:   db 0xff, 0x00, 0xff, 0xff, 0x00, 0xff, 0xff, 0x00, 0xff, 0xff, 0x00, 0xff, 0xff, 0x00, 0xff, 0xff 
soloPrimero: db 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
soloUltimo:  db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff

section .text
global edge_asm
edge_asm:

	push rbx ; alineada
	push r12 ; Desalineada
	push r13 ; Alineada
	push r14 ; Desalineada
	push r15 ; Alineada

	; Copio los parametros de entrada
	mov rbx, rdi    ; rbx = src
	mov r12, rdx    ; r12 = width
	mov r13, rcx    ; r13 = height
	mov r14, rsi    ; r14 = dst
	mov r15, r9     ; r15 = dst_row_size
	mov r11, r8     ; r11 = src_row_size

	xor r10, r10    ; contador imagen entera
	xor r9, r9      ; contador alto
	dec r13         ; para detectar cuando solo falta la ultima fila
	xor r8, r8      ; contador de tres iteraciones
	mov rcx, r12    ; contador ancho
    

.cicloPrimeraFila:
	movdqu xmm0, [rbx+r10]  ; agarro 16 pixeles de la imagen
	movdqu [r14+r10], xmm0
	add r10, 16
    sub rcx, 16
    cmp rcx, 0
    jl .arreglarPrimerFila
	je .finCicloPrimeraFila
	jmp .cicloPrimeraFila

.arreglarPrimerFila:
	add r10, rcx
	sub r10, 16
	mov rcx, 16
	jmp .cicloPrimeraFila

.finCicloPrimeraFila:
	pxor xmm0, xmm0
	add r9, 1       ; sumo 1 fila
	mov rcx, r12    ; contador ancho


; Ciclo principal
.ciclo:
	cmp r9, r13
	je .ultimaFila

	; ME TRAIGO LOS PIXELES DE LA FILA ANTERIOR Y DE LA FILA SIGUIENTE
	movdqu xmm1, [rbx+r10] 		; agarro 16 pixeles de la imagen
	sub r10, r12
	movdqu xmm2, [rbx+r10] 		; fila anterior
	add r10, r12
	add r10, r12
	movdqu xmm4, [rbx+r10] 		; fila siguiente
	sub r10, r12

	;  x | p2 |  x  |   x | p5 |  x  |   x | p8 |  x  |    x | p11 |   x  |    x | p14 |   x  |	   x
	;  x |  x | p3  |   x |  x | p6  |   x |  x | p9  |    x |   x | p12  |    x |   x | p15  |	   x
	;  x |  x |  x  |  p4 |  x |  x  |  p7 |  x |  x  |  p10 |   x |   x  |  p13 |   x |   x  |  p16

	;  x | p2 | p3  |  p4 | p5 | p6  |  p7 | p8 | p9  |  p10 | p11 | p12  |  p13 | p14 | p15  |  p16
	

	; Fila anterior
	pxor xmm13, xmm13
	movdqu xmm3, xmm2
	punpcklbw xmm2, xmm13			; desenpaqueto los bytes a words, me quedo con la parte baja
	punpckhbw xmm3, xmm13			; desenpaqueto los bytes a words, me quedo con la parte alta

	; Fila anterior parte baja
	movdqu xmm14, [mascara_Laplace_extremos_baja]
	movdqu xmm5, xmm2
	pand xmm2, xmm14	; me quedo con los extremos de la matriz
	psrlw xmm2, 1		; divido extremos por 2
	movdqu xmm14, [mascara_Laplace_centro_baja]
	pand xmm5, xmm14	; me quedo con el centro
	por xmm2, xmm5	    ; junto extremos modificados con centro intacto
	
	; Fila anterior parte alta
	movdqu xmm14, [mascara_Laplace_extremos_alta]
	movdqu xmm5, xmm3
	pand xmm3, xmm14
	psrlw xmm3, 1
	movdqu xmm14, [mascara_Laplace_centro_alta]
	pand xmm5, xmm14
	por xmm3, xmm5


	; Fila siguiente
	movdqu xmm5, xmm4
	punpcklbw xmm4, xmm13			; desenpaqueto los bytes a words, me quedo con la parte baja
	punpckhbw xmm5, xmm13			; desenpaqueto los bytes a words, me quedo con la parte alta

	; Fila siguiente parte baja
	movdqu xmm14, [mascara_Laplace_extremos_baja]
	movdqu xmm6, xmm4
	pand xmm4, xmm14
	psrlw xmm4, 1
	movdqu xmm14, [mascara_Laplace_centro_baja]
	pand xmm6, xmm14
	por xmm4, xmm6
	
	; Fila siguiente parte alta
	movdqu xmm14, [mascara_Laplace_extremos_alta]
	movdqu xmm6, xmm5
	pand xmm5, xmm14
	psrlw xmm5, 1
	movdqu xmm14, [mascara_Laplace_centro_alta]
	pand xmm6, xmm14
	por xmm5, xmm6


	; Fila actual
	movdqu xmm6, xmm1
	movdqu xmm7, xmm1
	punpcklbw xmm6, xmm13			; desenpaqueto los bytes a words, me quedo con la parte baja
	punpckhbw xmm7, xmm13			; desenpaqueto los bytes a words, me quedo con la parte alta

	; Fila actual parte baja
	movdqu xmm14, [mascara_Laplace_centro_baja]
	movdqu xmm8, xmm6
	pand xmm6, xmm14
	movdqu xmm15, [mascara_Laplace_seis_baja]
	pmullw xmm6, xmm15
	movdqu xmm14, [mascara_Laplace_extremos_baja]
	pand xmm8, xmm14
	por xmm6, xmm8

	; Fila actual parte alta
	movdqu xmm14, [mascara_Laplace_centro_alta]
	movdqu xmm8, xmm7
	pand xmm7, xmm14
	movdqu xmm15, [mascara_Laplace_seis_alta]
	pmullw xmm7, xmm15
	movdqu xmm14, [mascara_Laplace_extremos_alta]
	pand xmm8, xmm14
	por xmm7, xmm8

	; Sumo partes bajas
	paddw xmm2, xmm4
	paddw xmm2, xmm6		;sumo pixeles de arriba y abajo
	movdqu xmm8, xmm2
	psrldq xmm8, 2			;shifteo 1 word, 2 bytes
	movdqu xmm9, xmm2
	pslldq xmm9, 2
	paddw xmm2, xmm8
	paddw xmm2, xmm9		; sumo los pixeles de la izquierda y de la derecha

	; Sumo partes altas
	paddw xmm3, xmm5
	paddw xmm3, xmm7 		; hasta aca le sume el pixel de arriba y el de abajo

    ; Al ultimo pixel de la parte baja falta sumarle el primer pixel de la parte alta
    movdqu xmm8, xmm3
    pslldq xmm8, 14
	paddw xmm2, xmm8

    movdqu xmm8, xmm3
	psrldq xmm8, 2			; shifteo 1 word, 2 bytes
	movdqu xmm9, xmm3
	pslldq xmm9, 2
	paddw xmm3, xmm8
	paddw xmm3, xmm9		; sumo los pixeles de la izquierda y de la derecha

	packuswb xmm2, xmm3		; empaqueto a byte

	; Rearmo pixeles
	movdqu xmm4, [soloCentro]
	pand xmm2, xmm4
    
	cmp r8, 1
	je .shifteoUno
	cmp r8, 2
	je .shifteoDos

.shifteoCero:
    ; Me guardo el xmm1 de la primer iteracion, pues luego xmm1 cambia
    movdqu xmm10, xmm1
	jmp .vuelvo

.shifteoUno:
    ; Me guardo el xmm1 de la segunda iteracion, pues luego xmm1 cambia
    movdqu xmm11, xmm1
	pslldq xmm2, 1
	jmp .vuelvo

.shifteoDos:
	pslldq xmm2, 2

.vuelvo:
	por xmm0, xmm2
	inc r10
	inc r8
	cmp r8, 3
	jl .ciclo
	xor r8, r8
	
	; Escritura
    mov rsi, 14				; me muevo 14 pixeles. genere 15, y necesito 1 menos
    mov rdi, 1              ; para escribir tengo que hacerlo 1 byte siguiente
	cmp rcx, r12
	je .primeraColumna

	psrldq xmm0, 1          ; escribo los 15 bytes mas altos, por lo que los paso a la parte baja
	cmp rcx, 16
	je .ultimaColumna
	jmp .moverPixeles

.primeraColumna:
	movdqu xmm14, [soloPrimero]
	pand xmm10, xmm14
	por xmm0, xmm10
	mov rsi, 15				; para la primer columna genere 16 pixeles => me muevo 15
    mov rdi, 0              ; por ser la primera fila escribo siempre al principio
	jmp .moverPixeles

.ultimaColumna:
	movdqu xmm14, [soloUltimo]
	pand xmm11, xmm14
	por xmm0, xmm11
	mov rsi, 16				; para la ultima columna genere 16 pixeles => me muevo 16
    mov rdi, 1

.moverPixeles:
	sub r10, 3              ; resto los 3 pixeles que me movi en el ciclo interno
    add r10, rdi            ; sumo para ver donde tengo que escribir en comparacion a donde lei
	movdqu [r14+r10], xmm0
    sub r10, rdi
	pxor xmm0, xmm0
	add r10, rsi
	sub rcx, rsi
	cmp rcx, 0
	jl .actualizarColumna
	je .actualizarFila
	jmp .ciclo

.actualizarColumna:
	add r10, rcx
	sub r10, 17
	mov rcx, 16
	jmp .ciclo

.actualizarFila:
    add r10, 1
	inc r9
	mov rcx, r12
	jmp .ciclo

.ultimaFila:
	movdqu xmm0, [rbx+r10]
	movdqu [r14+r10], xmm0
	add r10, 16
	sub rcx, 16
	cmp rcx, 0
    jl .arreglarUltimaFila
	je .fin
	jmp .ultimaFila

.arreglarUltimaFila:
	add r10, rcx
	sub r10, 16
	mov rcx, 16
    jmp .ultimaFila

.fin:
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbx
ret


; 512 - 18 = 494
; 494 - 510
; 495 - 511
; 496 - 512

