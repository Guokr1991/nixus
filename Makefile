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

$(proj): $(proj).c xcorr_sse.o xcorr_avx.o xcorr_nat.o 
	$(CC) -o $@ $^ $(SSEFLAGS) $(LDFLAGS);\

$(proj).dbg: $(proj).c xcorr2d_sse.o
	$(CC) -o $@ $^ $(DBGFLAGS) $(LDFLAGS)

.PHONY: force_look

force_look: 
	true
