;; Intel x68-64 assembly code to calculate cross correlation
;; using SSE instructions, where the value domain is the
;; Naturals

        segment .text
        global xcorr_nat
xcorr_nat:
;; Pseudo declarations	      
; rdi, rsi, rdx, rcx, r8, r9
;
;       rdi:  x array
;       rdi:  y array
;       rcx:  loop counter
;       rdx:  n
;       xmm0: 2 parts of sum_x
;       xmm1: 2 parts of sum_y
;       xmm2: 2 parts of sum_xx
;       xmm3: 2 parts of sum_yy
;       xmm4: 2 parts of sum_xy
;       xmm5: 2 x values - later squared
;       xmm6: 2 y values - later squared
;       xmm7: 2 xy values
	;; Initialization
        xor     r8, r8
        mov     rcx, rdx
        subpd   xmm0, xmm0
        movdqa   xmm1, xmm0
        movdqa   xmm2, xmm0
        movdqa   xmm3, xmm0
        movdqa   xmm4, xmm0
        movdqa   xmm8, xmm0
        movdqa   xmm9, xmm0
        movdqa   xmm10, xmm0
        movdqa   xmm11, xmm0
        movdqa   xmm12, xmm0
	;; Main loop
.more:
	movdqa  xmm5, [rdi+r8]  ; mov x
        movdqa  xmm6, [rsi+r8]  ; mov y
        movdqa  xmm7, xmm5      ; mov x
        pmuludq   xmm7, xmm6      ; xy
        paddq   xmm0, xmm5      ; sum_x
        paddq   xmm1, xmm6      ; sum_y
        pmuludq   xmm5, xmm5      ; xx
        pmuludq   xmm6, xmm6      ; yy
        paddq   xmm2, xmm5      ; sum_xx
        paddq   xmm3, xmm6      ; sum_yy
        paddq   xmm4, xmm7      ; sum_xy
	add	r8, 64
	sub	rcx, 2
	jnz	.more
	ret
	
