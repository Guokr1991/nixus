\datethis

\def\title{x86 64-Bit Assembly}


@* Introduction. This manuscript contains technical information 
and tips for optimizing x86-64 assembly code. It is a difficult task
to mantain the document updated because changes in the processor are 
very fast, but we intend to put some good tips and techniques that 
are more stable.

@p
@h
@<Includes@>@;
#define __x86_N 4

@<Prototypes@>@;

int main(argc, argv)
     int argc;
     char**argv;
{Uint64 *x, *y;
  Uint64 n=__x86_N;
  Uint16 i;
  
  x = (Uint64 *)calloc(n, sizeof(Uint64));
  y = (Uint64 *)calloc(n, sizeof(Uint64));
  
  for (i=0; i<n; i++) {
    *(x+i) = (Uint64)i+1;
    *(y+i) = (Uint64)2*i+1;
  }

  xcorr_nat(x, y, n);

  return 0;
}

@ Common includes.

@<Includes@>=
#include <stdio.h>
#include <stdlib.h>
#include "nixus.h"

@ Cross correlation function.

@<Proto...@>=
extern Float xcorr_nat(Uint64 x[], Uint64 y[], Uint64 n);


@* SSE2 128-Bit SIMD Integer Instructions. Integer values can be 
processed using SSE2 instruction specific for this purpose. 128-Bit 
data can be stored in the registers. 

The XMMMx-registers introduced in the SSE2 instruction set 
  extensions store 128-bit that can be aligned as follows:


\hfil\vbox{
\+1$\times$ 128-bit raw integer&\cr  
\+2$\times$ 64-bit integer&\cr
\+4$\times$ 32-bit integer&\cr
\+8$\times$ 16-bit integer&\cr
\+16$\times$ 8-bit integer&\cr
\+2$\times$ 64-bit floating point values&\cr
\+4$\times$ 32-bit floating point values&\cr
}

	
@ {\tt MOVDQA} moves aligned double quadword, as an example,
the instruction

$$\vbox{\+\tt MOVEQDA xmm2/m128, xmm1\cr}$$

fetchs the content of {\tt xmm1} and moves it to {\tt xmm2}. 
The {\tt MOVDQA} operation corresponds to:

$$\vbox{\+\tt DEST $\leftarrow$ SRC;\hfill\cr}$$

@ {\tt PADDQ} instruction with 128-Bit operands

$$\vbox{\+\tt PADDQ xmm1, xmm2/m128;\cr}$$

\noindent adds packed quadword integers xmm2/m128 to xmm1. 
The {\tt PADDQ} corresponds to:

$$\tt\settabs 4\columns
\vbox{\+DEST[63-0] $\leftarrow$ DEST[31-0] + SRC[31-0];\hfill&&&\cr
      \+DEST[127-64] $\leftarrow$ DEST[95-64] + SRC[95-64];&\cr}
$$

@ {\tt PMULUDQ} instruction with 128-Bit operands

$$\vbox{\+\tt PMULUDQ xmm1, xmm2/m128;\cr}$$

\noindent multiplies packed unsigned doubleword integers in {\tt xmm1} 
 packed unsigned douboeword integers in {\tt xmm2$/$m128}, and store 
  quadword results {\tt xmm1}. The {\tt PMULUDQ} operation corresponds
  to:

$$\tt\settabs 4\columns
\vbox{\+DEST[63-0] $\leftarrow$ DEST[31-0] * SRC[31-0];\hfill&&&\cr
      \+DEST[127-64] $\leftarrow$ DEST[95-64] * SRC[95-64];&\cr}
$$

@* Index.
