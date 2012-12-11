;; Intel x68-64 assembly code to calculate cross correlation
;; using SSE2 instructions, where the value domain is the
;; Naturals.
;; A detailed description about the instructions is written
;; at ../../nixus.w
;; Author: Adriano J. Holanda
;; ajholanda@gmail.com
;; License: Apache v2
;; http://www.apache.org/licenses/LICENSE-2.0.txt
	segment .data
one	dq	1
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
        xor    	 	r8, r8
        mov     	rcx, rdx
        subpd   	xmm0, xmm0
        movdqa   	xmm1, xmm0
        movdqa   	xmm2, xmm0
        movdqa   	xmm3, xmm0
        movdqa   	xmm4, xmm0
	movdqa   	xmm8, xmm0
	movdqa   	xmm9, xmm0	
	;; Main loop
.more:
	movdqa  	xmm5, [rdi+r8]  ; mov x
        movdqa  	xmm6, [rsi+r8]  ; mov y
	paddq		xmm0, xmm5	; sum_x
	paddq		xmm1, xmm6	; sum_y
	movdqa   	xmm7, xmm5	; tmp <- x
	pmuldq		xmm7, xmm6	; xy
	pmuldq		xmm5, xmm5	; xx
	pmuldq		xmm6, xmm6	; yy
	paddq   	xmm2, xmm5      ; sum_xx
	paddq   	xmm3, xmm6      ; sum_yy
	paddq   	xmm4, xmm7      ; sum_xy
	add		r8, 16
	sub		rcx, 2
	jnz		.more
	haddpd		xmm0, xmm0	; sum_x
	cvtdq2pd	xmm0, xmm0   	; int => float
	haddpd		xmm1, xmm1	; sum_y
	cvtdq2pd	xmm1, xmm1   	; int => float
	haddpd		xmm2, xmm2	; sum_xx
	cvtdq2pd	xmm2, xmm2   	; int => float
	haddpd		xmm3, xmm3	; sum_yy
	cvtdq2pd	xmm3, xmm3   	; int => float	
	haddpd		xmm4, xmm4	; sum_xy
	cvtdq2pd	xmm4, xmm4   	; int => float	
	cvtsi2sd	xmm8, rdx 	; n
	mulsd		xmm4, xmm8	; n*sum_xy
	movsd		xmm9, xmm0	; tmp <- sum_x
	mulsd		xmm9, xmm1	; sum_x*sum_y
	subsd		xmm4, xmm9	; num <- n*sum_xy - sum_x*sum_y
	mulsd		xmm2, xmm8	; n*sum_xx
	mulsd		xmm0, xmm0	; sum_x*sum_x
	subsd		xmm2, xmm0	; den0 <- n*sum_xx - sum_x*sum_x
	sqrtsd		xmm2, xmm2	; den0 <- srqt(den0)
	mulsd		xmm3, xmm8	; n*sum_yy
	mulsd		xmm1, xmm1	; sum_y*sum_y
	subsd		xmm3, xmm1	; den1 <- n*sum_yy - sum_y*sum_y
	sqrtsd		xmm3, xmm3	; den1 <- srqt(den1)
	mulsd		xmm2, xmm3	; den <- den0 * den1
	movsd		xmm9, xmm2	; tmp <- den
	comisd		xmm4,xmm9	; den == num
	jz		DEN_EQUALS_NUM ; den = num
	divsd		xmm4, xmm2	; xcorr <- num/den
	movsd		xmm0, xmm4	; return xcorr
	ret
DEN_EQUALS_NUM:
	movsd		xmm0, [one]   	; xcorr = 1
	cvtdq2pd	xmm0, xmm0   	; int => float	
	ret

