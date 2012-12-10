include Makefile.inc

OBJS:=xcorr_sse.o xcorr_avx.o xcorr_nat.o
DBGFLAGS:=-g -pg
arch-dir:=arch
x86-64-dir:=$(arch-dir)/x86-64

$(proj).h: $(proj).c

$(proj).tex: $(proj).w
	$(WEAVE) -b $<

$(proj).pdf: $(proj).tex
	$(TEX) $< && \
	cp $@ ~/Dropbox

xcorr_sse.o: force_look
	cd $(x86-64-dir); $(MAKE) ../../$@

xcorr_avx.o: force_look
	cd $(x86-64-dir); $(MAKE) ../../$@

xcorr_nat.o: force_look
	cd $(x86-64-dir); $(MAKE) ../../$@

$(proj): $(proj).c $(OBJS)
	$(CC) -o $@ $^ $(SSEFLAGS) $(LDFLAGS);\

$(proj).dbg: $(proj).c $(OBJS) 
	$(CC) -o $@ $^ $(DBGFLAGS) $(LDFLAGS)

.PHONY: bench clean force_look
bench:
	for i in 10000 20000 30000 40000 50000 60000 70000 80000 90000 \
		 100000 200000 300000 400000 500000 600000 700000 900000 \
		 1000000 2000000 3000000 4000000 5000000 6000000 7000000 9000000 \
		 10000000 20000000 30000000 40000000 50000000 60000000 70000000 90000000; \
	do \
		echo "n=$$i";\
		./nixus.dbg -t $$i;\
		echo ""; \
	done

force_look: 
	true
