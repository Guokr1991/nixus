include ../Makefile.inc

../x86.c: ../x86.w
	$(CTANGLE) $<

../xcorr_sse.o: xcorr_sse.asm
	$(ASM) -Worphan-labels -o $@ -f elf64 -g dwarf2 -l corr.lst $<

../xcorr_avx.o: xcorr_avx.asm
	$(ASM) -Worphan-labels -o $@ -f elf64 -g dwarf2 -l corr.lst $<

../xcorr_nat.o: xcorr_nat.asm
	$(ASM) -Worphan-labels -o $@ -f elf64 -g dwarf2 -l corr.lst $<
