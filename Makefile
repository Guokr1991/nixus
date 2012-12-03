include Makefile.inc

$(proj).h: $(proj).c

$(proj).tex: $(proj).w
	$(WEAVE) -b $<

$(proj).pdf: $(proj).tex
	$(TEX) $< && \
	cp $@ ~/Dropbox

xcorr_sse.o: force_look
	cd asm; $(MAKE) ../$@

xcorr_avx.o: force_look
	cd asm; $(MAKE) ../$@

xcorr_nat.o: force_look
	cd asm; $(MAKE) ../$@

x86: x86.c xcorr_nat.o
	$(CC) -o $@  $(CFLAGS) -ggdb $^ $(LDFLAGS)

$(proj): $(proj).c xcorr_sse.o xcorr_avx.o 
	$(CC) -o $@ $^ $(SSEFLAGS) $(LDFLAGS);\
	make backup

$(proj).dbg: $(proj).c xcorr2d_sse.o
	$(CC) -o $@ $^ $(DBGFLAGS) $(LDFLAGS)
	make backup

.PHONY: force_look

force_look: 
	true
