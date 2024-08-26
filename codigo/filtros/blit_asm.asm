%define offset_blit 16
%define offset_bw 24
%define offset_bh 32
%define offset_b_row_size 40

section .data
DEFAULT REL

section .rodata 
magenta: dd 0xffff00ff, 0xffff00ff, 0xffff00ff, 0xffff00ff

section .text
global blit_asm

; rdi   -> puntero src      (unsigned char)
; rsi   -> puntero dst      (unsigned char)
; rdx   -> w                (int)
; rcx   -> h                (int)
; r8    -> src_row_size     (int)
; r9    -> dst_row_size     (int)
; pila  -> blit             (unsigned char)
; pila  -> bw               (int)
; pila  -> bh               (int)
; pila  ->b_row_size        (int)

blit_asm:
;COMPLETAR
    push rbp
    mov rbp, rsp
    sub rsp, 8
    push rbx
    push r12
    push r13
    push r14
    push r15
    ; Pila alineada

    mov r8, rdi                       ;r8 -> puntero a src
    mov rbx, [rbp+offset_blit]        ;rbx -> puntero a blit
    mov r12, [rbp+offset_bw]          ;r12 -> bw
    mov r13, [rbp+offset_bh]          ;r13 -> bh
    mov r11, rsi                      ;r11 ->pintero a dst

    xor r15, r15            ;r15 -> contador ancho
    xor r14, r14            ;r14 -> contador alto
    xor r9, r9              ;r9 -> pixeles en la imagen
    xor r10, r10            ;r10 -> posicion en la imagen de peron

    movdqu xmm3, [magenta]

    .ciclo:

    movdqu xmm5, [r8+r9] ;xmm5 -> 4 pixeles de la imagen src

    mov rdi, rdx
    sub rdi, r12
    cmp rdi, 0
    jl .copiar_a_dst
    mov rdi, rcx
    sub rdi, r13
    cmp rdi, 0
    jl .copiar_a_dst          ;Si la imagen a filtrar es mas chica que la de peron, no aplico filtro

    mov rdi, rcx
    sub rdi, r13
    sub rdi, r14              
    cmp rdi, 0
    jg .copiar_a_dst
    mov rax, rdx
    sub rax, r12
    sub rax, r15               
    cmp rax, 0
    jg .copiar_a_dst_b

    movdqu xmm1, [rbx+r10]  ;xmm1 -> 4 pixeles de la imagen de peron
    movdqu xmm2, xmm1
    pcmpeqd xmm2, xmm3
    pand xmm5, xmm2   ;xmm5 -> pasan los pixeles donde la imagen de peron tienen magenta
    pcmpeqd xmm4, xmm4
    pandn xmm2, xmm4
    pand xmm1, xmm2  ;xmm1 -> pixeles de la imagen de peron que no son magenta
    por xmm5, xmm1  ;xmm5 -> pixeles no magentas de la imagen de peron, superpuestos a los de la imagen src
    
    mov rax, rdx
    sub rax, r15
    cmp rax, 8
    jl .estoy_llegando_al_borde 
    add r10, 16

    .copiar_a_dst:
    movdqu [r11+r9], xmm5
    add r9, 16
    add r15, 4
    cmp r15, rdx  
    je .actualizarAnchoYLargo  ;Si llegue al ancho de la imagen entonces paso a la siguiente fila
    jmp .ciclo

    .actualizarAnchoYLargo:
    inc r14
    cmp r14, rcx
    je .fin         ;Si r14 es igual al alto de la imagen, entonces ya recorri todas las filas y termine
    xor r15, r15
    jmp .ciclo

    .copiar_a_dst_b:  ;Esto lo hago para no entrar corrido a la imagen de peron
    cmp rax, 3
    jg .copiar_a_dst
    movdqu [r11+r9], xmm5
    add r9, 4
    add r15, 1
    jmp .ciclo

    .estoy_llegando_al_borde: ;Si me quedan menos de 4 pixeles para llegar al borde, avanzo de a 1
    movdqu [r11+r9], xmm5
    cmp rax, 4
    je .llegue_al_borde ;Si no me quedan pixeles es porque llegue al borde
    add r9, 4
    add r15, 1
    add r10, 4
    jmp .ciclo

    .llegue_al_borde:
    add r9, 16
    add r10, 16
    jmp .actualizarAnchoYLargo

    .fin:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    add rsp, 8
    pop rbp

  ret
