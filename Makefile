CFLAGS 		:=		-Wall -g
LDFLAGS		:=		-lpng -lm 
proj 		:=		nixus
subprojs	:=		ncc match plane
tests		:=		$(addprefix test_,$(subprojs))
TEX		:=		pdflatex
CWEAVE		:=		cweave
TANGLE		:=		ctangle
refs		:=		refs.bib
ETAGS		:= 		/usr/bin/etags

.PHONY: 			clean cleanall doc
vpath				%.w sgb

$(proj).tex:			$(proj).w
				$(CWEAVE) $<


$(proj).pdf: 			$(proj).tex $(refs)
				$(TEX) $<
doc: 				$(proj).pdf
docdoc:				doc
				bibtex $(proj) && \
				$(TEX) $(proj).tex && \
				$(TEX) $(proj).tex

%.c:				$(proj).w
%.o:				$(proj).c

gb_graph.c:			gb_graph.w gb_graph.ch
				$(TANGLE) $^

gb_graph.h: 			gb_graph.c

$(proj).h:			gb_graph.h

$(proj).o:			$(proj).c
				$(CC) -c $< $(CFLAGS) $(CV_CFLAGS)

$(proj): 			$(proj).o gb_graph.o
				$(CC) -o $@ $^ $(LDFLAGS)


TAGS:				$(proj).c gb_graph.c
				if [ -f $(ETAGS) ]; then etags $^; fi

$(addsuffix .c,$(tests)):	$(proj).c
.SECONDEXPANSION:
$(tests):			$$@.c $(proj).o gb_graph.o
				$(CC) -o $@ $^ $(CFLAGS) $(LDFLAGS)

clean:
				$(RM) $(tests) ;\
				$(RM) *~ *.c *.h $(proj)*.png *.py *.o ; \
				$(RM) *.aux *.bbl *.blg *.idx *.log *.out *.scn *.tex *.toc

cleanall: 			clean
				$(RM) $(proj).pdf TAGS
