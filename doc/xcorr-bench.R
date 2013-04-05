#require(tikzDevice)
#tikz('xcorr-bench.tex', standAlone = FALSE, width=4.25, height=3.75)
png(file='xcorr-bench.png', bg='transparent');
data<-read.table("xcorr-bench.dat", sep="\t");
# BAR PLOT
#elems <- data$V1
#xcorrnames <- list(c("C","x86-64"), elems)
#xcorrdata=matrix(c(data$V2,data$V3),nrow=2,byrow=TRUE,dimnames=xcorrnames)
#barplot(xcorrdata, beside=TRUE, xlab="Número de elementos da série", ylab="Número de ciclos no processador", main="Cálculo da correlação cruzada")

#POINT PLOT
plot(x=data$V1,y=data$V2,type='o',pch=19,col='black', ylab='Número de ciclos no processador',xlab='Número de pontos por série')
points(x=data$V1,y=data$V3, type="o", pch=17, col='black', lty=2)
legend(x=10000,y=7e8,legend=c("x86-64 SSE Assembly ", " C "), col=c("black", "black"), lwd=1, cex=1, pch=19:17, lty=1:2)
dev.off()
