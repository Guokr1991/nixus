proj:=nixus
WEAVE:=cweave
TANGLE:=ctangle
TEX=pdftex
ASM=yasm
CC=gcc
CFLAGS:=-Wall -ansi -msse4
DBGFLAGS:=$(CFLAGS) -ggdb -pg
# flags for intel SSE extension
SSEFLAGS=$(CFLAGS) -malign-double -funroll-all-loops
LDFLAGS:=-lm

vpath %.asm asm

$(proj).tex: $(proj).w
	$(WEAVE) -b $<

$(proj).pdf: $(proj).tex
	$(TEX) $< && \
	cp $@ ~/Dropbox

xcorr2d_sse.o: xcorr2d_sse.asm
	$(ASM) -Worphan-labels -f elf64 -g dwarf2 -l corr.lst $<

xcorr2d_avx.o: xcorr2d_avx.asm
	$(ASM) -Worphan-labels -f elf64 -g dwarf2 -l corr.lst $<

$(proj): $(proj).c xcorr2d_sse.o xcorr2d_avx.o 
	$(CC) -o $@ $^ $(SSEFLAGS) $(LDFLAGS);\
	make backup

$(proj).dbg: $(proj).c xcorr2d_sse.o
	$(CC) -o $@ $^ $(DBGFLAGS) $(LDFLAGS)
	make backup

.PHONY: backup clean
backup: $(proj).w
	cp $(proj).w ~/Dropbox/
clean:
	$(RM) $(proj) $(proj).dbg $(proj).c *.o \
	$(proj).tex $(proj).pdf *.idx *.log *.scn *.toc\
	toy.rf

