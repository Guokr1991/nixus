artigo-simd.pdf: artigo-simd.tex sse.png sseop.png
	pdflatex $<

sse.png:
	inkscape -e $@ img/SSE.svg

sseop.png:
	inkscape -e $@ img/SSEop.svg

xcorr-bench.png: xcorr-bench.R
	Rscript $^

.PHONY:
clean:
	$(RM) *~ *.aux *.dvi *.idx *.fo *.html *.log *.nav *.out *.pdf *.snm *.xml report-2012.tex
