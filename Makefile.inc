proj:=nixus
WEAVE:=cweave
TANGLE:=ctangle
TEX=pdftex
ASM=yasm
CC=gcc
CFLAGS:=-Wall -msse4
DBGFLAGS:=$(CFLAGS) -ggdb -pg
# flags for intel SSE extension
SSEFLAGS=$(CFLAGS) -malign-double -funroll-all-loops
LDFLAGS:=-lm

.PHONY: clean

clean:
	$(RM) -r $(proj) $(proj).dbg $(proj).c *.o \
	$(proj).tex $(proj).pdf *.idx *.log *.scn *.toc\
	_region_* auto toy.rf
