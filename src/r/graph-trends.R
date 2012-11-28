library(TTR)
library(dtw)
library(reshape)
library(ggplot2)
source("clean-econ.R")
source("utils.R")

load("../../data/processed/cluster-count-01.Rdata")
load("../../data/processed/snap-econ.Rdata")

## Limit analysis and graphing to only years of "good" data
sub.data <- full.data[get.year(full.data$date) >= 2008,]
sub.econ <- snap.econ[get.year(snap.econ$date) >= 2008,]

## Convenient labels for IDN and MYS data, separated
idn <- sub.data[sub.data$cntry == "idn", ]
mys <- sub.data[sub.data$cntry == "mys", ]

policy.bars <- function(g) {
  ## Add shaded grey bars to the supplied ggplot time series,
  ## according to the dates of the three stages of the moratorium
  rect.df <- function(begin, end) {
    data.frame(xmin=as.Date(begin), xmax=as.Date(end), ymin=-Inf, ymax=Inf)
  }

  custom.bars <- function(x) {
    geom_rect(data=x, aes(xmin=xmin, xmax=xmax, ymin=ymin, ymax=ymax),
              alpha=0.20, inherit.aes = FALSE)
  }
  
  announce <- rect.df("2010-03-10", "2010-05-20")
  intent   <- rect.df("2010-10-20", "2011-01-01")
  enact    <- rect.df("2011-03-10", "2011-05-20")

  g <- g + custom.bars(announce)
  g <- g + custom.bars(intent)
  g <- g + custom.bars(enact)
  g
}

## graph land characteristics
graph.land <- function(iso, land.type, out.name = FALSE) {
  if (out.name == FALSE) {
    name <- paste(iso, "-", land.type, ".png", sep="")
    f <- file.path("../../write-up/images", name)
  }
  new <- paste("new.", land.type, sep=""); old <- paste("old.", land.type, sep="")
  g.data <- sub.data[sub.data$cntry == iso, c("date", new, old)]
  g.data <- melt(g.data, id="date")
  names(g.data) <- c("date", "cluster.type", "land.char")
  g <- ggplot(data = g.data, aes(x = date, y = land.char, colour = cluster.type)) + geom_line()
  g <- g + xlab("") + ylab("")
  ggsave(f, g)
}

## Create date, price, and IDN exchange rate objects to be used
## throughout the rest of the script to graph the time series
date  <- sub.econ[["date"]]
price <- sub.econ[["price"]]
post  <- ifelse(date > as.Date("2011-01-01"), 1, 0)
idn.exch <- sub.econ[["idn.exch"]]
exch.ratio <- idn.exch / sub.econ[["mys.exch"]]

## Graph economic data using ggplot

## Graph IDN exchange rate
png("../../write-up/images/idn-exchrate.png")
g <- ggplot(data=econ.data, aes(x=date, y=idn.exch)) + geom_line()
(g <- g + xlab("") + ylab("$/Rp exchange rate"))
dev.off()

## Graph MYS exchange rate
png("../../write-up/images/mys-exchrate.png")
g <- ggplot(data=econ.data, aes(x=date, y=mys.exch)) + geom_line()
(g <- g + xlab("") + ylab("mys/$ exchange rate"))
dev.off()

## Graph palm price
png("../../write-up/images/palm-price.png")
g <- ggplot(data=econ.data, aes(x=date, y=price)) + geom_line()
(g <- g + xlab("") + ylab("$/ton"))
dev.off()

## Graph the price of oil palm and the IDN exchange rate, noting that
## they will be overlaid in a presentation, such that both lines are
## graphed in both price.png and price-exch.png, with the transparency
## of the exchange rate toggled

png("../../write-up/images/price.png", width=800, height=600)
par(mar=c(5,4,4,5)+.1)
plot(date, price, type="l", xlab="", ylab="Palm price ($/ton)")
par(new=TRUE)
plot(date, idn.exch, type="l", xlab="", ylab="", axes=FALSE,
     xaxt="n", yaxt="n", col="transparent", lty=2)
axis(4)
mtext("Indonesian exchange rate ($/Rp)", side=4, line=3)
dev.off()

png("../../write-up/images/price-exch.png", width=800, height=600)
par(mar=c(5,4,4,5)+.1)
plot(date, price, type="l", xlab="", ylab="Palm price ($/ton)")
par(new=TRUE)
plot(date, idn.exch, type="l", xlab="", ylab="", axes=FALSE,
     xaxt="n", yaxt="n", col="red", lty=2)
axis(4)
mtext("Indonesian exchange rate ($/Rp)", side=4, line=3)
dev.off()

## Graph physical data

## Graph slopes
graph.land("idn", "slope")
graph.land("mys", "slope")

## Graph water accumulation
graph.land("idn", "accum")
graph.land("mys", "accum")

## Graph elevation
graph.land("idn", "elev")
graph.land("mys", "elev")

## Graph total deforestation rates for Indonesia and Malaysia

png("../../write-up/images/total-rate.png", width=800, height=600)
plot(idn$date, idn$total, type="l", xlab="", ylab="Total deforestation")
lines(mys$date, mys$total, type="l", col = "red", lty=2)
dev.off()

## Graph warping

## create the warping object between the smoothed proportions of new
## deforestation that occurs in new clusters
d <- dtw(idn$s.prop, mys$s.prop, step.pattern=symmetricP2, keep.internals=TRUE)

## graph the raw time series of the smoothed proportions for indonesia
## and malaysia.  We do it this way, using dtwPlotTwoWay() so that the
## axes line up exacty when we show the match between the time series
## -- ultimately to overlay in a presentation.
png("../../write-up/images/ref-match.png", width=800, height=600)
dtwPlotTwoWay(d, idn$s.prop, mys$s.prop, match.col="transparent", ylab="")
dev.off()

## graph the smoothed proportion time series with matching lines
png("../../write-up/images/match.png", width=800, height=600)
dtwPlotTwoWay(d, idn$s.prop, mys$s.prop, ylab="", match.col="darkgray", match.lty=2)
dev.off()

## graph the difference between the smoothed proportion time series,
## without any warping
png("../../write-up/images/diff.png", width=800, height=600)
plot(idn$date, idn$s.prop - mys$s.prop, type="l", xlab="", ylab="Difference", col="blue")
dev.off()

## create a new difference between the smoothed proportion time
## series, one that allows for warping, or matching that occurs in
## more than just the vertical dimension.
idn.val <- idn$s.prop[d$index1]
mys.val <- mys$s.prop[d$index2]
diff <- idn.val - mys.val
df <- data.frame(idx=d$index1, diff=diff)
warped.diff <- aggregate(df, by=list(df$idx), FUN=mean)$diff

## Overlay the raw and warped differences
png("../../write-up/images/warped-diff.png", width=800, height=600)
plot(date, idn$s.prop - mys$s.prop, type="l", xlab="", ylab="Difference", col="blue")
lines(date, warped.diff, type="l", xlab="", ylab="Warped difference", col="red")
dev.off()

## Graph only the warped time series, noting that we want the axes to
## remain the same as the previous graph, so plotting the raw,
## unwarped difference with a transparent color
png("../../write-up/images/warped-diff-only.png", width=800, height=600)
plot(date, idn$s.prop - mys$s.prop, type="l", xlab="", ylab="Difference", col="transparent")
lines(date, warped.diff, type="l", xlab="", ylab="Warped difference", col="red")
dev.off()

## Graph the warped difference with the price trend to show how the
## difference measure moves with price.  Specifically, that after the
## moratorium, the difference did not respond to price in the same way
## as it had before the moratorium
png("../../write-up/images/diff-price.png", width=800, height=600)
plot(date, idn$s.prop - mys$s.prop, type="l", xlab="", ylab="Difference", col="transparent")
lines(date, warped.diff, type="l", xlab="", ylab="Warped difference", col="red")
par(new=TRUE)
plot(date, price/1000, type="l", xlab="", ylab="", axes=FALSE, xaxt="n", yaxt="n")
dev.off()

png("../../write-up/images/diff-price-exch.png", width=800, height=600)
plot(date, idn$s.prop - mys$s.prop, type="l", xlab="", ylab="Difference", col="transparent")
lines(date, warped.diff, type="l", xlab="", ylab="Warped difference", col="red")
par(new=TRUE)
plot(date, price/1000, type="l", xlab="", ylab="", axes=FALSE, xaxt="n", yaxt="n")
par(new=TRUE)
plot(date, idn.exch, type="l", xlab="", ylab="", axes=FALSE,
     xaxt="n", yaxt="n", lty=2)
dev.off()

png("../../write-up/images/diff-exch.png", width=800, height=600)
plot(date, idn$s.prop - mys$s.prop, type="l", xlab="", ylab="Difference", col="transparent")
lines(date, warped.diff, type="l", xlab="", ylab="Warped difference", col="red")
par(new=TRUE)
plot(date, price/1000, type="l", xlab="", ylab="", axes=FALSE, xaxt="n", yaxt="n", col="transparent")
par(new=TRUE)
plot(date, idn.exch, type="l", xlab="", ylab="", axes=FALSE,
     xaxt="n", yaxt="n", lty=2)
dev.off()

## Basic summary stats

## (1) if we use a "symmetric" step function in the dtw() function,
## like symmetricP1, then we get a better fit between, but need to lag
## the price variable to see a statistically significant change in the
## responsiveness of the difference to price

## (2) if we us an "asymmetric" step function in the dtw() function,
## like asymmetricP1, then we don't need to lag because the random
## error falls in our direction.

(m1 <- summary(lm(warped.diff ~ post + price)))
(m2 <- summary(lm(warped.diff ~ price + post + exch.ratio)))

gcol1 <- rgb(red=0, green=0, blue=255, alpha=100, max=255)
gcol2 <- rgb(red=255, green=0, blue=0, alpha=100, max=255)
png("../../write-up/images/scatter-diff.png", width=800, height=600)
plot(price, warped.diff, cex=1.5, col=gcol1, pch=19)
dev.off()

png("../../write-up/images/new-scatter-diff.png", width=800, height=600)
plot(price, warped.diff, cex=1.5, col="transparent", pch=19)
points(price[post == 0], warped.diff[post == 0], cex=1.5, col=gcol1, pch=19)
points(price[post == 1], warped.diff[post == 1], cex=1.5, col=gcol2, pch=19)
dev.off()

png("../../write-up/images/hyp-diff.png", width=800, height=600)
plot(price, warped.diff, cex=1.5, col="transparent", pch=19)
points(price[post == 0], warped.diff[post == 0], cex=1.5, col=gcol1, pch=19)
points(price[post == 1], warped.diff[post == 1] - m1$coefficients[2,1], cex=1.5, col=gcol2, pch=19)
new.diff <- c(warped.diff[post == 0], warped.diff[post == 1] - m1$coefficients[2,1])
dev.off()

png("../../write-up/images/hyp-diff-line.png", width=800, height=600)
plot(price, warped.diff, cex=1.5, col="transparent", pch=19)
points(price[post == 0], warped.diff[post == 0], cex=1.5, col=gcol1, pch=19)
points(price[post == 1], warped.diff[post == 1] - m1$coefficients[2,1], cex=1.5, col=gcol2, pch=19)
new.diff <- c(warped.diff[post == 0], warped.diff[post == 1] - m1$coefficients[2,1])
abline(lm(new.diff ~ price), col="darkgrey", lwd=5)
dev.off() 




diff <- idn$s.prop - mys$s.prop
summary(lm(diff ~ price + post + idn.exch))
summary(lm(diff ~ price + post + exch.ratio))

## The slopes within the different groups
summary(lm(warped.diff[post == 0] ~ price[post == 0]))
summary(lm(warped.diff[post == 1] ~ price[post == 1]))

## price <- SMA(price, 23)
## summary(lm(warped.diff ~ price*post))
## summary(lm(warped.diff ~ price*post + exch.ratio))
