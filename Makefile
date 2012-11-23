proj:=nixus
WEAVE:=cweave
TANGLE:=ctangle
TEX=pdftex
CC=gcc
CFLAGS:=-Wall -ansi
DBGFLAGS:=$(CFLAGS) -ggdb -pg
# flags for intel SSE extension
SSEFLAGS=$(CFLAGS) -mssse3 -malign-double
LDFLAGS:=-lm

$(proj).tex: $(proj).w
	$(WEAVE) -bx $<

$(proj).pdf: $(proj).tex
	$(TEX) $<

$(proj): $(proj).c
	$(CC) -o $@ $< $(SSEFLAGS) $(LDFLAGS)

$(proj).dbg: $(proj).c
	$(CC) -o $@ $< $(DBGFLAGS) $(LDFLAGS)

.PHONY: clean
clean:
	$(RM) $(proj) $(proj).dbg $(proj).c $(proj).o test_* \
	$(proj).tex $(proj).pdf *.idx *.log *.scn *.toc

