@s int8_t int
@s uint8_t int
@s int16_t int
@s uint16_t int
@s int32_t int
@s uint32_t int
@s int64_t int
@s uint64_t int
@s pixel_t int

\documentclass{cweb}
\usepackage{tikz}
\usepackage{amssymb,amsmath}
\usepackage{hyperref}

\def\pname{NIXUS}
\title{\pname}
\author{Adriano J. Holanda\footnote{Contact: \href{mailto:aholanda@@usp.br}{aholanda@@usp.br}}, 
Theo Pavan, Thenysson Lemos and Adilton Carneiro}

\begin{document}
\maketitle

@* Introduction. The word \pname{}, that means strain in Latin, is the
name of the project to manipulate RF files generated by Ultrasonix
SonixRP system containing ultrasound scan lines in raw format. The
objective of this project is to measure displacements in the material
being scanned using differences in the RF frames according to the time
captured as parameter. The header |nixus.h| contains macros, type
definitions and function prototypes used in the project.

@(nixus.h@>=
#ifndef __NIXUS_H__
#define __NIXUS_H__
@<Nixus header header files@>@;
#define GB_GRAPH /* this chunk avoids new gb\_graph.h inclusions */
@<Type definitions@>@;
@<Macro declarations@>@;
@<Prototypes@>@;
#endif

  
@ @p
@<Header files@>@;
@<Private variables@>@;
@<Internal functions@>@;
@<Functions@>@;


@ Common header files.
@<Header...@>=
#include <assert.h>
#include <errno.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "nixus.h"


@* Ultrasonix. There is a rich bunch image formats that can be produced by 
  Ultrasonix equipment. The |u_file_header| contains information needed
  to extract data properly. The |type| variable is assigned to |u_data_type| 
  and in this project, the type of interest is |udtRF|.

@<Type...@>=
  enum u_data_type{
  udtScreen= 0x00000001, /* Compressed file of screen captures */
  udtBPre= 0x00000002, /* Envelope detected B data */
  udtBPost= 0x00000004, /* Interpolated and post-processed B data */
  udtBPost32= 0x00000008, /* Interpolated and post-processed B data 32 bit */
  udtRF= 0x00000010, /* Pre or Post-beamformed RF data */
  udtMPre= 0x00000020, /* Envelope detected and log-compressed M lines */
  udtMPost= 0x00000040,/* Interpolated M line data stored as a single spectrum capture */
  udtPWRF= 0x00000080, /* Doppler RF gate data acquired at the Doppler PRF */
  udtPWSpectrum= 0x00000100, /* Interpolated FFT data stored as a single spectrum capture */
  udtColorRF= 0x00000200, /* Color RF data acquired at the Color PRF with full packet-size */
  udtColorCombined= 0x00000400, /* Interpolated and processed B and color data */
  udtColorVelocityVariance= 0x00000800, /* Interpolated and processed color velocity (Y) 
					   and variance data (X). Variance is power data in 
					   Power Doppler mode  */
  udtElastoCombined= 0x00002000, /* Interpolated and processed B and elastography data */
  udtElastoOverlay= 0x00004000, /* Interpolated and processed elastography data */
  udtElastoPre= 0x00008000, /* Midway processed elastography data before interpolation, 
			       and after RF and strain conversion */
  udtECG= 0x00010000, /*ECG spectrum data */
  udtGPS= 0x00020000, /* GPS co-ordinate data */
  udtPNG= 0x10000000 /* PNG data ?*/
};

struct u_file_header {
  enum u_data_type type; /* data type (can be determined by file extensions) */
  int frames; /* number of frames in file */
  int w;      /* width (number of vectors for raw, 
		image width for processed data) */
  int h;      /* height (number of samples for raw, 
		image height for processed data) */
  int ss;     /* data sample size in bits */
  int ulx;    /* roi - upper left (x) */
  int uly;    /* roi - upper left (y) */
  int urx;    /* roi - upper right (x) */
  int ury;    /* roi - upper right (y) */
  int brx;    /* roi - bottom right (x) */
  int bry;    /* roi - bottom right (y) */
  int blx;    /* roi - bottom left (x) */
  int bly;    /* roi - bottom left (y) */
  int probe;  /* probe identifier - additional probe information 
		 can be found using this id */
  int txf;    /* transmit frequency in Hz */
  int sf;     /* sampling frequency in Hz */
  int dr;     /* data rate (fps or prp in Doppler modes) */
  int ld;     /* line density (can be used to calculate element spacing if
		 pitch and native number of elements is known  */
  int extra;  /* extra information (ensemble for color RF) */
};

@ The {\tt u\_*} macros are defined to access Ultrasonix file header
information, acting as interface and avoiding direct access to
variables.

@<Macro...@>=
#define u_nframes(ufh) ufh->frames
#define u_frame_width(ufh) ufh->w
#define u_frame_height(ufh) ufh->h
#define u_sample_size(ufh) ufh->ss /* sample size in bits */

@ @<Proto...@>=
 extern void u_print_file_header(struct u_file_header*ufh);

@ The |u_print_file_header| function prints the information about
Ultrasonix file and is useful to debug purposes.
@<Functions@>=
void u_print_file_header(struct u_file_header *h){
  printf("Header information:\n");
  printf("|- data type: %d\n",h->type);
  printf("|- number of frames: %d\n",h->frames);
  printf("|- width (number of vectors): %d\n",h->w);
  printf("|- height (number of samples): %d\n",h->h);
  printf("|- data sample size in bits: %d\n",h->ss);
  printf("|- roi - upper left (x): %d\n",h->ulx);
  printf("|- roi - upper left (y): %d\n",h->uly);
  printf("|- roi - upper right (x): %d\n",h->urx);
  printf("|- roi - upper right (y): %d\n",h->ury);
  printf("|- roi - bottom right (x): %d\n",h->brx);
  printf("|- roi - bottom right (y): %d\n",h->bry);
  printf("|- roi - bottom left (x): %d\n",h->blx);
  printf("|- roi - bottom left (y): %d\n",h->bly);
  printf("|- probe identifier: %d\n",h->probe);
  printf("|- transmit frequency (Hz): %d\n",h->txf);
  printf("|- sampling frequency (Hz): %d\n",h->sf);
  printf("|- data rate: %d\n",h->dr);
  printf("|- line density: %d\n",h->ld);
  printf("|- extra information: %d\n",h->extra);
  printf("|- number of bytes per frame: %d\n", 4 + h->w * h->h * h->ss/8);
  printf("|- number of pixels per frame: %d\n", 4 + h->w * h->h);

  return;
}


@* RF. Pre or post-beamformed RF image has the following specification.
\begin{table}[h]
\begin{tabular}{ll}
  Type:& {RF}\\
  Description:& Pre or Post-beamformed RF data\\
  Organization:& Vector\\
  Bytes per pixel/Format:& 16/RF\\
  Frame size& FC + (V * S * 2)\\
  Extension:& .rf\\
\end{tabular}\\
\end{table}

\noindent where,\\
  FC=4 byte header\\
  V=vectors (number of scan lines)\\
  S=samples (number of incident pulses per scan line line represented by 2-byte header).\\

RF file is loaded into memory as |struct RF|, saving the |file_header|
information and the pixels into |data|. The |area| is part of a memory
management scheme used by SGB (Stanford GraphBase). The concept of
type |Area| is simple and powerful because all memory allocations are
performed using |gb_typed_alloc| function, also from SGB, allowing
safe and unique deallocation.

@<Type...@>=
@<Pixel type definition@>@;
struct RF {
  struct u_file_header *file_header; /* header with file and RF information */
  pixel_t *data; /* array containing pixel values */
  Area area;
};

@ Private variable |cur_rf| is used to maintain a internal global
pointer to pass |struct RF| through the program.
@<Private...@>=
  static struct RF *cur_rf;

@ Each RF pixel is 2-byte size (16 bits). |MAX_PIX_VAL| ($2^{15}-1$)
  is the maximum pixel value that can be assigned to RF sample. The
  minimum pixel value is 32,767 ($2^{15}$). This range is due the type
  assigned to |pixel_t|. The type can be changed according to the
  pixel manipulation needs, but a careful attention must be paid to
  assigned correct values for limits.

@<Pixel type definition@>=
#ifdef pixel_t
#undef pixel_t
#endif
#define pixel_t int16_t
#define MAX_PIX_VAL 32767


@ Some macros to access RF information are defined to expose
a clean accession interface.
@<Macro...@>=
#define RF_FRAME_HEADER_SZ 4 /* 4-byte frame header */
#define RF_FRAME_HEADER_NPIX 2 /* number of pixels in the frame header (each pixel is 2-byte) */
#define rf_frame_nvectors(rf) u_frame_width(rf->file_header)
#define rf_frame_nsamples(rf) u_frame_height(rf->file_header)
#define rf_nframes(rf) u_nframes(rf->file_header)
#define rf_frame_npixels(rf) (RF_FRAME_HEADER_NPIX + rf_frame_nvectors(rf)*rf_frame_nsamples(rf)) /* in  pixels\_t */
#define rf_frame_nbytes(rf) (rf_frame_npixels(rf)*RF_FRAME_HEADER_NPIX) /* in bytes */
#define rf_npixels(rf) ((rf_frame_npixels(rf))*rf_nframes(rf))
#define rf_nbytes(rf) (rf_npixels(rf)*RF_FRAME_HEADER_NPIX) /* in bytes */

@*1 {RF data}.The lines are recorded as showed in the
Figure~\ref{fig:rflines}, where each sample is recorded as it arrives, and
after all, the map must be reshaped where the coordinate $(0,1)$
becomes $(1,0)$, for example, reconstructing the RF data as it is
formed after processing in B-mode.

  \begin{figure}[h]
  \begin{tikzpicture}
  [sample/.style={anchor=east,font=\scriptsize,minimum width=.6cm,minimum height=.5cm,draw},
   hmax/.style={sample,anchor=west,minimum width=1cm}]

  \node[draw] at (-4.75cm,3) {\scriptsize 76-byte file header};

  \def\slabel{{\ifnum\x=-1{4-byte frame header} %
	\else\ifnum\x=9{$\ldots$} %
	    \else\x\fi\fi}} %
  \foreach \x in {-1,0,1,...,8,9} {
    \ifnum\x=9{
      \node[hmax] at (.6*\x, 3) {$h-1$};
      \node[hmax] at (.6*\x, 2) {$h-1$};
      \node[hmax] at (.6*\x, 1) {$h-1$};
    }
    \fi
    \node[sample] at (.6*\x cm,3) {\color{red}{\slabel}};
    \node[sample] at (.6*\x cm,2) {\color{blue}{\slabel}};
    \node[sample] at (.6*\x cm,1) {\color{green}{\slabel}};
  }
  \end{tikzpicture}
  \caption{Layout of RF data. Each scan line has 4-byte frame header and $h$ samples.
      The samples are stored as pulses come into transducer, from top to bottom.}
  \label{fig:rflines}
\end{figure}

\pagebreak
  
@ A pixel at position \((x, y)\) on frame number $FN$ is obtained by
using the formula~(\ref{pixelposition}):\\

\begin{equation}
  \label{eq:pixelposition}
  \text{FN} \times \text{number\_of\_pixels\_per\_frame} \\
  + \text{number\_of\_frame\_header\_pixels}\\
  + x\times \text{number\_of\_samples\_per\_vector}\\
  + y
\end{equation}

  The pixel value can be obtained by using |rf_pixel| macro, and all information needed
  is available in the RF file header. Remember the value on y axis goes from $0$ to $h$,
  from top to bottom, a common standard when dealing with images to simplify the 
  image transverse reasoning.

  \begin{figure}[ht]
  \begin{tikzpicture}
  [sample/.style={anchor=east,font=\scriptsize,minimum width=.75cm,minimum height=.75cm,draw},
   hmax/.style={sample,anchor=south east,minimum width=.5cm,text width=.475cm}]

   \node[anchor=west] at (-6,-1) {\small FrH -- 4-byte frame header};
   \node[anchor=west, text width=4cm] at (-6,-2) {\small $h-1$ -- number of samples minus one};

  \def\slabel{{\ifnum\x=-1{FrH} %
	\else\ifnum\x=9{$\vdots$} %
	    \else\x\fi\fi}} %
  \foreach \x in {-1,0,1,...,8,9} {
    \node[sample] (o\x) at (0,-.75*\x cm) {\color{red}{\slabel}};
    \node[sample] (i\x) at (1,-.75*\x cm) {\color{blue}{\slabel}};
    \node[sample] (ii\x) at (2,-.75*\x cm) {\color{green!40!black!70}{\slabel}};
  }
  \node[hmax] [below of=o9,yshift=.22cm] {\tiny $h-1$};
  \node[hmax] [below of=i9,yshift=.22cm] {\tiny $h-1$};
  \node[hmax] [below of=ii9,yshift=.22cm] {\tiny $h-1$};
  \end{tikzpicture}
  \caption{Each one of the $h$ samples of RF data must be disposed in
    the vertical direction To be converted into images. File frame
    header is loaded into {\tt file\_header}, and the rest stored into
    {\tt data}. Note: frame header was maintained and must be ignored
    when extract samples to process.}
  \label{fig:rfcols}
  \end{figure}

  The |rf_pixel_prt| returns the address of the pixel in the $(x,y)$
  position of the |frame_id|. The mapping of RF as showed in
  Figure~\ref{fig:rflines} (scan lines) to RF as showed in
  Figure~\ref{fig:rfcols} (image) is done to access the right pixel at
  the desired position.

@<Macro...@>=
#define rf_pixel_ptr(rf, frame_no, x, y) (rf->data		\
+ rf_frame_npixels(rf)*frame_no				\
+ RF_FRAME_HEADER_NPIX				\ 
+ (x)*rf_frame_nsamples((rf))			\
+ (y))
#define rf_pixel(rf, frame_no, x, y) *rf_pixel_ptr(rf, frame_no, x, y)

@ Generating and accessing matrix elements.
@<Macro...@>=
#define matrix_t int32_t

@ @<Proto...@>=
  extern matrix_t *rf_matrix(struct RF*rf, size_t frame_no);

@ We sum up the absolute lower bound of |int16_t| ($[-32768,32767)$), that 
  is 32768, to manipulate positive values used to determine the regions
  in the planar graph. We extend the |int| size to 32 bits to accommodate 
  the sum.
@<Functions@>=
  matrix_t *rf_matrix(rf, frame_no)
     struct RF *rf;
     size_t frame_no;
{
  matrix_t *m;
  int64_t x, y;

  assert(frame_no>=0);
  assert(frame_no < rf_nframes(rf));

  m = gb_typed_alloc(rf_frame_npixels(rf)*sizeof(matrix_t), matrix_t, rf->area);
  for (y=0; y<rf_frame_nsamples(rf); y++)
    for (x=0; x<rf_frame_nvectors(rf); x++)
      m[x+y] = 32768 + rf_pixel(rf, frame_no, x, y);

  assert(m);
  return m;
}
  
@ The |gb_graph.h| contains the data structures and memory management
(as |gb_typed_alloc|) facilities that we will use. The header
inclusion will be passed if the |GB_GRAPH| is defined elsewhere,
indicating that the header was already included.  

@<Nixus header...@>=
#ifndef GB_GRAPH 
#include "gb_graph.h" 
#endif

@ The |rf_new| only allocate the needed space to |struct RF| and
|struct u_file_header|, and initialize |Area|. The content of created
|struct rf| is filled after invoking |rf_read| with the RF file name as
parameter and with the created RF assigned to |cur_rf|.

@<Prototypes@>=
  extern struct RF *rf_new();
  extern void rf_free(struct RF*rf);
  extern struct RF *rf_read(const char *rf_filename);

@ @<Functions@>=
  struct RF *rf_new()
    {
      cur_rf = (struct RF*)calloc(1, sizeof(struct RF));
      if (!cur_rf)
	die("Trouble code: %d.", alloc_fault);
      
      init_area(cur_rf->area);
      
      cur_rf->file_header = gb_typed_alloc(1, struct u_file_header, cur_rf->area);
      if (!cur_rf->file_header) {
	gb_free(cur_rf->area);
	die ("Could not allocate memory.");
      }

      assert(cur_rf->area);
      assert(cur_rf->file_header);
      return cur_rf;
    }
  
void rf_free(rf)
     struct RF *rf;
{
  if (!rf)
    return;
  
  if (rf->data)
    free(rf->data);
  
  if (rf->area)
    gb_free(rf->area);
  
  free(rf);
}

struct RF *rf_read(rf_filename)
const char*rf_filename; /* RF file name */
{
  FILE *rf_file;
  struct RF *rf;

  assert(rf_filename);
  rf = rf_new();
  
  if ((rf_file = fopen(rf_filename, "rb")) == NULL)
      die("Could not open the file %s: %s\n", rf_filename, strerror(errno));

  init_area(rf->area);
  @<Extract and print RF file header@>@;
  @<Allocate memory and fill with RF data@>@;
  
  fclose(rf_file);
    
  assert (rf);
  assert (rf->data);
  assert(rf_nframes(rf)>0);

  return rf;
  
}

@ File header is read to extract information about the 
  RF data incorporated, then it is printed to inform 
  how data is structured.
@<Extract and print RF file header@>=
  fread(rf->file_header, sizeof(struct u_file_header), 1, rf_file);
  if (rf->file_header->type != udtRF)/* verify if the file is RF type 0x10 = 16 */
      die("The file %s seems not to be in RF format.\n", rf_filename);
  u_print_file_header(rf->file_header);

@ A quantity |data_sz| of memory for |rf_data| is allocated in the heap and 
  filled with binary data obtained from RF file. The |rf_data| contains
  all RF frame headers and frames.

@<Allocate memory and fill with RF data@>=
  rf->data = (pixel_t *)calloc(1, rf_nbytes(rf));

if (!rf->data) {
  rf_free(rf);
  die("Could not allocate memory.");
 }
fread(rf->data, rf_nbytes(rf), 1, rf_file);


@* Normalized Cross-Correlation (NCC). NCC is frequently used as a
method to determine correlation between two data series. This method
is used to calculate the pairwise correlation between RF
sub-frames. The reference data is compared with template, where the
template in our case is the RF images acquired normally after some
deformation is induced in the sample exposed to ultrasound pulse.

\def\dt{{\Delta~t}}

{\footnotesize\begin{equation}
  \label{eq:ncc} NCC_k(t)=\frac{
    \sum\limits_{k=1}^{n}
    \{[I_k(t)-M(I(t))]\times[I_k(t^\prime)-M(I(t^\prime))]\}
  }{
    \sqrt{\sum\limits_{k=1}^{w}[I_k(t)-M(I(t))]^2
    \times\sum\limits_{k=1}^{n}[I_k(t^\prime)-M(I(t^\prime))]^2}
  }
  \end{equation}}
\noindent where:\\
$NCC$~-~normalized cross-correlation,\\
$k$~--~index, \\
$I$~--~pixel intensity,\\
$M$~--~mean;\\
$t$~--~acquisition time of the reference signal;\\
$t^\prime$~--~difference of the template acquisition time from the reference.

|REFERENCE| image index is assigned to $0$ and |TARGET| to 1. The
|REFERENCE| image is divided into sub-frames that are regions to be
tracked against the |TARGET| to find the differential strain. The
|struct coordinate| is a wrapper to $(x,y)$ coordinates.

@<Type...@>=
 enum {REFERENCE=0, TARGET=1};
 struct coordinate {
    long x;
    long y;
  };
 struct subframe {
   unsigned long frame_id; /* frame number */
   struct coordinate top_left; /* top left coordinate of sub-image */
   struct coordinate bottom_right; /* bottom right coordinate of sub-image */
 };

 

@ @<Proto...@>=
 extern double rf_ncc(struct RF*rf, @|
		      struct subframe *reference, @\
		      struct subframe *target);
		       
@ @<Functions@>=
double rf_ncc(rf, ref, tar)
 struct RF *rf;	 /* RF data to work on */
 struct subframe *ref; /* reference sub-frame to track */
 struct subframe *tar; /* target sub-frame to calculate the correlation with reference */
{
  register long j;
  register unsigned long dx, dy; /* how many pixels to transverse in x and y */
  register unsigned long x, y; /* x, y sub-frame coordinates */
  double mean[2];

  assert(rf!=NULL);
  assert(ref!=NULL);
  assert(tar!=NULL);

  @<Local variables for |rf_ncc|@>@;
  @<Initialize |dx|, |dy| and assert the equivalence in geometry between sub-frames@>@;
  @<Initialize mean...@>@;
  for (y=0; y<dy; y++) {
    for (x=1; x<dx; x++) {
      @<Update mean and standard deviation@>@;
      @<Update numerator of normalized cross correlation formula@>@;
    }
  }
    @<Calculate normalized cross correlation@>@;

    return ncc;
  }

@ @<Initialize |dx|, |dy|...@>=
      dx = ref->bottom_right.x-ref->top_left.x;
dy = ref->bottom_right.y-ref->top_left.y;
assert((ref->bottom_right.x-ref->top_left.x) ==
       (tar->bottom_right.x-tar->top_left.x));
assert((ref->bottom_right.y-ref->top_left.y) ==
       (tar->bottom_right.y-tar->top_left.y));

@ The mean of |REFERENCE| and |TARGET| images is initialized to the
first pixel in that images. This follows the Formula~\ref{eq:mean} to
calculate the mean as a recurrence series.

@<Initialize mean values@>=
mean[REFERENCE] = (double)rf_pixel(rf, ref->frame_id, 0, 0);
mean[TARGET] = (double)rf_pixel(rf, tar->frame_id, 0, 0);


@*1 Mean and standard deviation. We might use the less possible naive
algorithm to calculate the mean and standard deviation to be used in
(\ref{eq:ncc}), because the number of elements to be compared is very
high. We choose the following recurrence formulas as suggested in
\cite{welford1962,taocp2}.

The formula~(\ref{eq:mean}) is used to update the mean during the
pairwise evaluation of elements:

\begin{align}
  \label{eq:mean}
M_1& = x_1, &M_K = M_{k-1} + (x_k - M_{k-1}) / k
\end{align}

\noindent for $2\leq k\leq n$. As $1\leq k\leq n$ and $0\leq j<n-1$,
that is used as index in the loop, then $k = j + 1$.

\bigskip

@<Local variables for |rf_ncc|@>=
register short i; /* index for reference [0] and target [1] data  */
register pixel_t *p; /* pixel pointer */
struct subframe *sf[2] = {ref, tar};
double last_mean[2] = {0.0, 0.0}; /* old value of mean */

@ @<Update mean and standard deviation@>=
  for (i = 0; i < 2; i++) {
    p = rf_pixel_ptr(rf, sf[i]->frame_id, 
		     sf[i]->top_left.x+x,
		     sf[i]->top_left.y+y);
    mean[i] = last_mean[i] + (*p - last_mean[i])/(x+y + 1);
    
    @<Update standard deviation@>@;
    @<Update denominator of normalized cross correlation formula@>@;
    last_mean[i] = mean[i];
  }

@ The formula~(\ref{eq:S}) is used to calculate the standard deviation 
  during the NCC calculation.

\begin{align}
  \label{eq:S}
S_1& = 0,  &S_k = S_{k-1} + (x_k - M_{k-1}) \times (x_k - M_k)
\end{align}

  for \(2\leq k\leq n\), where \(\sigma=\sqrt{S_n/(n-1)}\).
\bigskip

@<Local variables for |rf_ncc|@>=
double S2[2] = {0.0, 0.0}; /* $S^2 = (p_i - \overline{p})^2$ */
double den[2] = {0.0, 0.0}; /* ncc denominator terms */
register double num=0; /* ncc numerator */
register double ncc = 0.0; /* ncc per se */

@ @<Update standard deviation@>=
  S2[i] +=  (*p - last_mean[i])*(*p - mean[i]);

@ @<Update denominator...@>=
  den[i] += S2[i];

@ @<Update numerator...@>=
  num += sqrt(S2[0])*sqrt(S2[1]);

@ @<Calculate normalized cross correlation@>=
  ncc =  num/ sqrt(den[0]*den[1]);


@ The following program performs a trivial test
  using normalized cross correlation function.

@(test_ncc.c@>=
@<Header...@>@;

#define N 10000L
      int main(int ac, char**av)
    {
      pixel_t *ref, *targ; /* reference and target */
      unsigned long i;
      double ncc;

      ref = (pixel_t *)calloc(1, sizeof(pixel_t)*N);
      targ = (pixel_t *)calloc(1, sizeof(pixel_t)*N);

      for (i = 0; i < N; i++) {
	*(ref+i) = i;
	//*(targ+i) = rand();
	*(targ+i) = *(ref+i) * 2;
      }
#if 1==2
      TODO redo the test reasoning
      ncc = rf_ncc(ref, targ);
#endif
      free(ref);
      free(targ);

      printf("Cross correlation=%f\n", ncc);

      return 0;
    }


@* Sub-frame matching. Sub-frames are divisions of the |REFERENCE| RF
image that are used to search the most correlate region in the image
used as |TEMPLATE|. The |reference_id| indicates the number of the RF
frame to be used as |REFERENCE|, and the |target_id| is the same to
|TARGET| image. The |ratio| type set the value to divide the columns
and lines to obtain the sub-frames. Sub-frame is not called region of
interest (ROI) to avoid collision with the same term used in the RF
file header. 

@<Proto...@>=
void rf_match(struct RF*rf, unsigned long rid, unsigned long tid, struct ratio r);

@ @<Type...@>=
struct ratio {
  int x;
  int y;
};

@ The |rf_match| function transverse all sub-frames in the reference
image and find the coordinates of most correlate area in the target
image that represents the strain in the sample.

@<Function...@>=
  void rf_match(rf, reference_id, target_id, ratio)
  struct RF*rf; /* reference image */
  unsigned long reference_id; /* index of reference image */
  unsigned long target_id; /* target index of image to compare with reference */
  struct ratio ratio; /* ratio in the row and column */
  {
    register double ncc=0;
    unsigned long i, dx=0, dy=0;
    unsigned long indices[2] = {reference_id, target_id}; 
    @<Local variables for |rf_match|@>@;

    @<Assert indices...@>@;

    debug("ratio(x,y)=(%d,%d)\n", ratio.x, ratio.y);

    dx = rf_frame_nvectors(rf)/(float)ratio.x; 
    dy = rf_frame_nsamples(rf)/(float)ratio.y; 
    
    debug("d(x,y)=(%lu,%lu)\n", dx, dy);

    @<Transverse the subdivisions in the reference image@>@;
    
    return;
  }

@ @<Assert indices are greater or equal than zero and not greater than
the number of frames@>=
  for (i=0; i<2; i++) {
    assert(indices[i] >= 0);
    assert(indices[i] < rf_nframes(rf));
  }

@ @<Local variables for |rf_match|@>=
  register unsigned long x, y, ncols, nrows;
  struct subframe *rsf, *tsf; /* temporary reference and target sub-frames */
  struct coordinate tl, br;
  

@ @<Transverse the subdivisions in the reference image@>=
  nrows = rf_frame_nsamples(rf);
  ncols = rf_frame_nvectors(rf);
  rsf = gb_typed_alloc(1, struct subframe, rf->area);
  tsf = gb_typed_alloc(1, struct subframe, rf->area);

  for (x=0; x<ncols; x+=dx)
    for (y=0; y<nrows; y+=dy) {
      @<Update reference subframe@>@;
      @<Find the best match in the target image@>@;
    }

@ @<Update reference subframe@>=
  tl.x=x;tl.y=y;
  br.x=x+dx;br.y=y+dy;
  subframe_new(rsf, reference_id, tl, br);

@ @<Local variables for |rf_match|@>=
  unsigned long xx, yy; /* indices for target subframe */

@ @<Find the best match in the target image@>=
  for (yy=x; yy+dy<nrows; yy++) {
    for (xx=y; xx+dx<ncols; xx++) {
      @<Update target subframe |tsf|@>@;
      ncc = rf_ncc(rf, rsf, tsf);
      if (ncc > 0.9)
	debug("NCC(%ld.(%ld,%ld), %ld.(%ld, %ld))=%f\n", 
	      reference_id, x, y, target_id, xx, yy, ncc);
      if (xx==8) break;
    }
  }


@ @<Update target subframe...@>=
  tl.x=xx;tl.y=yy;
  br.x=xx+dx;br.y=yy+dy;
  subframe_new(tsf, target_id, tl, br);

@ @<Internal...@>=
  static void subframe_new(sf, frame_id, top_left, bottom_right)
  struct subframe *sf;
  unsigned long frame_id;
  struct coordinate top_left, bottom_right; /* top-left and bottom-right coordinates */
  {
    assert(sf != NULL);
    assert(top_left.x<bottom_right.x);
    assert(top_left.y<bottom_right.y);
    
    sf->frame_id = frame_id;
    sf->top_left = top_left;
    sf->bottom_right = bottom_right;
  }

@ @(test_match.c@>=
@<Header...@>@;
    int main(argc, argv)
    int argc;
    char**argv;
  {
    struct RF *rf;
    struct ratio ratio = {.x=4, .y=8};
    ((void )0);

    rf = rf_read(RF_TEST_FILENAME);
    
    rf_match(rf, 0, 4, ratio);

    return 0;
  }



@*0 Output. Some output formats are used to store the image frames and 
  the results of processing for analysis and visualization.

\nopagebreak
@*1 Encapsulated PostScript (EPS). EPS is used when there is a need to
print or fast visualization (faster than pgm) of the results.

@d EPS_VERSION "%%!PS-Adobe-3.0 EPSF-3.0"

@ The function |eps_write| output the RF map in the EPS format.
@<Internal functions@>=
  static void eps_write(rf, frame_no, output_filename)
  @<Common arg...@>@;
    {
	FILE *eps_file;
	register float conv = 255.0/(float)MAX_PIX_VAL;
	
	@<Declarations and statements for *\_write@>@;

	eps_file = fopen(output_filename, "w");
	if (!eps_file)
	  die("Could not open \"%s\" file for writing.", output_filename);

	fprintf(eps_file, "%s\n", EPS_VERSION);
	fprintf(eps_file,"%%%%BoundingBox: -1 -1 %lu %lu\n", ncols+1, nrows+1);
	fprintf(eps_file,"/buffer %ld string def\n", ncols);
	fprintf(eps_file,"%ld %ld 8 [%ld 0 0 -%ld 0 %ld]\n",ncols, nrows, ncols, nrows, nrows);
	fprintf(eps_file,"{currentfile buffer readhexstring pop} bind\n");
	fprintf(eps_file,"gsave %ld %ld scale image\n", ncols, nrows);
	for (y = 0; y < nrows; y++)
	  @<Output column value...@>;
	fprintf(eps_file,"grestore\n");
	
	fclose(eps_file);
    }

@ @<Declarations and statements for *\_write@>=
  @<Declare common local variables for *\_write@>@;
  @<Assert some constraints about the arguments for *\_write@>@;
  @<Initialize common local variables for *\_write@>@;

@ @<Common arguments for *\_write@>=
  struct RF *rf; /* pointer to RF data */
  uint16_t frame_no; /* frame to be written */
  char *output_filename; /* file name to output */

@ @<Declare common local variables for *\_write@>=
  FILE *fp;
  register uint64_t nrows, ncols; /* number of rows and columns of image */
  register uint64_t x, y; /* general purpose indices */
  pixel_t p;

@ @<Assert some constraints about the arguments for *\_write@>=
  assert (rf);
  assert (output_filename);
  assert (rf->file_header);
  assert (rf->data);
  assert (frame_no >= 0);
  assert (frame_no < rf_nframes(rf));

@ @<Initialize common local variables for *\_write@>=
  nrows = rf_frame_nsamples(rf);
  ncols = rf_frame_nvectors(rf);
  fp = fopen(output_filename, "w");
  if (!fp)
    die("Could not open \"%s\" file for writing.", output_filename);


@ @<Output column value as hexadecimal string@>=
  {
    for (x = 0; x < ncols; x++) {
      p = (pixel_t) (conv * (float)rf_pixel(rf, frame_no, x, y));
      fprintf (eps_file, "%02x", p > 255 ? 255 : p);
      
    if (((x+y) & 0x1F) == 0x1f)
      fprintf (eps_file, "\n");
    }
    if ((ncols+nrows) & 0x1f)
      fprintf (eps_file, "\n");
  }

@*1 Portable Gray Map (PGM). PGM is used when there is a need to
inspect pixel value to debug the algorithms.

@<Internal...@>=
  static void pgm_write(rf, frame_no, output_filename)
  @<Common arg...@>@;
  {

    @<Declarations and statements for *\_write@>@;
        
    fprintf (fp, "P2\n");
    fprintf (fp, "# frame %u/%u\n", frame_no+1, rf_nframes(rf));
    fprintf (fp, "%lu %lu\n", ncols, nrows);
    fprintf (fp, "%d\n", MAX_PIX_VAL);

    uint16_t v;

    for (y = 0; y < nrows; y++) {
      for (x = 0; x < ncols; x++)  {
	p = (pixel_t) rf_pixel(rf, frame_no,  x, y);
	
	v = (p + MAX_PIX_VAL)/65535.0 * 255.0;
	
	fprintf (fp, "%d\t", p);
      }
      fprintf(fp, "\n");
    }
    
    fclose(fp);
    return;
  }

@* CSV. CSV format is used when the output is desirable to be taken as
input by some spreadsheet. 

@<Internal...@>=
  static void csv_write(rf, frame_no, output_filename)
  @<Common arg...@>@;
  {
    @<Declarations and statements for *\_write@>@;

    for (y = 0; y < nrows; y++) {
      for (x = 0; x < ncols; x++)  {
	p = (pixel_t) rf_pixel(rf, frame_no,  x, y);
	fprintf (fp, "%lu\t%lu\t%d\n", y, x, p);
      }
      fprintf (fp, "\n");
    }
    
    fclose(fp);
    
    return;
  }


@* Graphs. Graphs are an alternative to NCC in the task of sub-frame
  matching. The number of points can be reduced by using planarity
  transformation and the stable matching algorithm o the planar
  graphs. Even though, this task is being developed as experimental,
  if the results become promising, graphs can be used due a plenty of
  proof-ready mathematical tools to be applied in the images.

@d NEW_REGION -(ncols + nrows)

@ @<Proto...@>=
  extern Graph *rf_plane(struct RF *rf, uint32_t frame_no);

@ The |rf_plane| function takes the pixel values as vertices and
construct a graph with the edges placed where the adjacent pixel
values are equal.

@<Functions@>=
  Graph *rf_plane(rf, frame_no)
  struct RF *rf;
  uint32_t frame_no;
  {
    assert(rf);
    assert(frame_no >= 0 && frame_no < rf_nframes(rf));
    
    return plane(rf_matrix(rf, frame_no), 
		 rf_frame_nvectors(rf), 
		 rf_frame_nsamples(rf),
		 rf->area);
  }

@ @<Proto...@>=
  Graph *plane(matrix_t *m, uint64_t ncols, uint64_t nrows, Area working_storage);
  
@ @<Functions@>=
  Graph *plane(m, ncols, nrows, working_storage)
  matrix_t *m; /* matrix per se with contiguous elements in memory */
  uint64_t ncols; /* number of columns of matrix */
  uint64_t nrows; /* number of rows of matrix */
  Area working_storage; /* managed memory */
  {
    matrix_t *apos; /* location of m[x,y] */
    int64_t x, y; /* row and column index */
    int64_t j; /* general purpose index */
    int64_t nregs = 0; /* number of components (regions)*/
    Graph *graph;
    @<Local variables for |plane|@>@;
    
    @<Look for the beginning of connected regions@>@;
    @<Set up a graph with |nregs| vertices@>@;
    @<Put the appropriate edges into graph@>@;

    return graph;
  }


@ @<Local variables for |plane|@>=
  uint64_t *f; /* beginning of array f */

@ @<Look for the beginning of connected regions@>=
  f = gb_typed_alloc(ncols, uint64_t, working_storage);
  if (!f) {
    gb_free(working_storage);
    die ("Could not allocate memory!\n");
  }

  for (y=nrows, apos=m+ncols*(nrows+1)-1; y>=0; y--)
    for (x=ncols-1; x>=0; x--, apos--) {
      if (y<nrows) {
	if (y>0 && *(apos-ncols) == *apos) {
	  for (j=x; f[j]!=j; j=f[j]) ;/* find the first element */

	  f[j] = x;
	  *apos = x;
	}@+ else if (f[x]==x) 
		   *apos = -1-*apos, nregs++; /* new region */
	  else
	    *apos = f[x];
      }
	
      if (y > 0 && x < ncols - 1 && *(apos-ncols) == *(apos - ncols+1))
	  f[x+1] = x;
	
	f[x] = x;

      }
  printf("\n\nNREGS=%ld\n\n", nregs);
  
@ 
@d pixel_value x.I
@d first_pixel y.I
@d last_pixel z.I
@d matrix_nrows uu.I
@d matrix_ncols vv.I
@<Set up a graph with |nregs| vertices@>=
  graph = gb_new_graph(nregs);
  if (!graph)
    die ("Could not allocate memory.");
  sprintf(graph->id, "plane(%lu,%lu)", ncols, nrows);
  strcpy(graph->util_types, "ZZZIIIZZIIZZZZ");
  graph->matrix_nrows = nrows;
  graph->matrix_ncols = ncols;
  
@ @<Local variables for |plane|@>=
  Vertex **u; /* table of vertices of previous |ncols| pixels */
  Vertex *v; /* vertex corresponding to position [x,y] */
  Vertex *w; /* vertex corresponding to position [x-1,y] */
  uint64_t loc; /* ncols*y + x */
  char str_buf[32];
  

@ @<Put the appropriate edges into graph@>=
  f = gb_typed_alloc(ncols, uint64_t, working_storage);
  if (f==NULL) {
    gb_free(working_storage);
    die("Could not allocate memory.");
  }
  u = (Vertex **)f;
  nregs = 0;
  for (x=0; x<ncols; x++) u[x] = NULL;
  for (y=0, loc=0; y<nrows; y++)
    for (x=0; x<ncols; x++, loc++) {
      w=u[x];

      if (m[x+y]<0) {
	sprintf (str_buf, "%ld", nregs);
	v = graph->vertices + nregs;
	v->name = gb_save_string(str_buf);
	v->pixel_value = -m[x+y] - 1; /* restore original pixel value */
	v->first_pixel = loc;

	printf("(%lu,%lu)=#reg=%ld name=%s pix=%ld 1st_pix=%ld\n", 
	       x,y, nregs, v->name, v->pixel_value, v->first_pixel);
	nregs++;
      } else {
	v = u[m[x+y]];
	printf("*m[%lu,%lu]=%d at %p\n", x,y,m[x+y],u[m[x+y]]);
      }

      u[x] = v;

      v->last_pixel = loc;

#if 1==2      
      if (y>0 && v!=w)
	adjac(v,w);
      if (x>0 && v!=u[x-1])
	adjac(v, u[x-1]);
#endif 
   }
    

@ @<Internal...@>=
  static void adjac(u, v)
  Vertex *u, *v;
  {
    Arc*a;
    
    assert(u);
    assert(v);

    for (a = u->arcs; a; a = a->next)
      if (a->tip == v)
	return;

    gb_new_edge(u, v, 1L);
  }

@ @<Macro...@>=
#define RF_TEST_FILENAME "/opt/nixus/data/elasto.rf"

@ @(test_plane.c@>=
@<Header...@>@;
int main()
  {

#if 1==2
    struct RF *rf;
    int i;
    char fn[32];

    rf = rf_read(RF_TEST_FILENAME);
    rf_plane(rf, 0, rf->area);
    rf_free(rf);
#endif

    Area a;
    init_area(a);
    matrix_t m[9] = {0,0,
		     0,0,
		     1,0};
    
    plane(&m[0], 2, 3, a);
    
    return 0;
  }


@* Utilities. The macro |die| shows a message with the line number,
file and function names, and |abort| the execution of the program. If
|NDEBUG| macro is defined, no error is evaluated and no |debug|
information is printed.

@<Macro...@>=
#ifdef NDEBUG
#define debug_err(format, ...) ((void *)(0))
#define debug(format, ...) ((void *)0)
#else
#define debug(format, ...) do {						\
      fprintf(stdout, "%d:%s->%s(): ", __LINE__, __FILE__, __FUNCTION__);	\
      fprintf(stdout, format, ## __VA_ARGS__ );				\
    } while(0)
#define debug_err(format, ...)						\
  fprintf(stderr, "%s->%s: %d ", __FILE__, __FUNCTION__, __LINE__);	\
  fprintf(stderr, format, ## __VA_ARGS__)
#endif

#define die(format, ...)  do {						\
    debug_err(format, ## __VA_ARGS__);					\
    abort();								\
  } while(0)


@* TODO. The following tasks are pending, and the priority are
assigned in the parentheses.

\begin{description}
\item[(0)] Refine the |rf_match| function to search a reasonable target
  image region, and step with a more accurate reasoning.
\item[(2)] Add multi-thread instructions in the target frames matching to take
  advantage of multi-core architecture of current processors.
\item[(4)] Implement the graphical interface with the elastography map. 
\end{description}

@
\bibliographystyle{plain}
\bibliography{refs}

\end{document}
