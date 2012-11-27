library(dtw)
library(reshape)
library(ggplot2)
source("clean-econ.R")
source("utils.R")

load("../../data/processed/cluster-count-01.Rdata")
sub.data <- full.data[get.year(full.data$date) >= 2008,]

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
  return(g)
}

## Graph total rates
png("../../write-up/images/total-rate.png", width=800, height=500)
g <- ggplot(data = sub.data, aes(x = date, y = total, colour = cntry)) + geom_line()
g <- policy.bars(g)
(g <- g + xlab("") + ylab(""))
dev.off()

idn <- sub.data[sub.data$cntry == "idn", ]
mys <- sub.data[sub.data$cntry == "mys", ]

## gcol <- col2alpha("grey", alpha = 0.5)
## png("../../write-up/images/total-rate.png", width=800, height=600)
## plot(c(as.Date("2008-01-01"), as.Date("2012-08-01")), c(350,1075), xlab="", ylab="Total deforestation", col="transparent")
## usr <- par('usr') 
## rect(as.Date("2010-01-01"), usr[3], as.Date("2011-01-01"), usr[4], col=gcol, border="transparent") 
## lines(mys$date, mys$total, type="l", col="red")
## lines(idn$date, idn$total, type="l", col="blue")
## dev.off()

png("../../write-up/images/total-rate.png", width=800, height=600)
plot(idn$date, idn$total, type="l", xlab="", ylab="Total deforestation")
lines(mys$date, mys$total, type="l", col = "red", lty=2)
dev.off()

## Graph smoothed proportion of deforestation in new clearing
png("../../write-up/images/smoothed-prop.png", width=800, height=600)
g <- ggplot(data = sub.data, aes(x = date, y = s.prop, colour = cntry)) + geom_line()
g <- policy.bars(g)
(g <- g + xlab("") + ylab(""))
dev.off()

png("../../write-up/images/smoothed-prop.png", width=800, height=600)
plot(c(as.Date("2008-01-01"), as.Date("2012-08-01")), c(0.045,0.10), xlab="", ylab="Proportion in new clusters", col="transparent")
usr <- par('usr') 
rect(as.Date("2010-01-01"), usr[3], as.Date("2011-01-01"), usr[4], col=gcol, border="transparent") 
lines(mys$date, mys$s.prop, type="l", col="red")
lines(idn$date, idn$s.prop, type="l", col="blue")
dev.off()

## Graph slopes
graph.land("idn", "slope")
graph.land("mys", "slope")

## Graph water accumulation
graph.land("idn", "accum")
graph.land("mys", "accum")

## Graph elevation
graph.land("idn", "elev")
graph.land("mys", "elev")

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

## Graph warping

## create the warping object
d <- dtw(idn$s.prop, mys$s.prop, step.pattern=symmetricP2, keep.internals=TRUE)

## graph the raw time series
png("../../write-up/images/ref-match.png", width=800, height=600)
dtwPlotTwoWay(d, idn$s.prop, mys$s.prop, match.col="transparent", ylab="")
dev.off()

## graph the raw time series with matching lines
png("../../write-up/images/match.png", width=800, height=600)
dtwPlotTwoWay(d, idn$s.prop, mys$s.prop, ylab="", match.col="darkgray", match.lty=2)
dev.off()

## graph the difference between the raw time series
png("../../write-up/images/diff.png", width=800, height=600)
plot(idn$date, idn$s.prop - mys$s.prop, type="l", xlab="", ylab="Difference", col="blue")
dev.off()

## create a new difference, one that allows for warping
idn.val <- idn$s.prop[d$index1]
mys.val <- mys$s.prop[d$index2]
diff <- idn.val - mys.val
df <- data.frame(idx=d$index1, diff=diff)
v <- aggregate(df, by=list(df$idx), FUN=mean)
png("../../write-up/images/warped-diff.png", width=800, height=600)
plot(idn$date, idn$s.prop - mys$s.prop, type="l", xlab="", ylab="Difference", col="blue")
lines(idn$date, v$diff, type="l", xlab="", ylab="Warped difference", col="red")
dev.off()

png("../../write-up/images/warped-diff-only.png", width=800, height=600)
plot(idn$date, idn$s.prop - mys$s.prop, type="l", xlab="", ylab="Difference", col="transparent")
lines(idn$date, v$diff, type="l", xlab="", ylab="Warped difference", col="red")
dev.off()


date <- idn$date
post <- ifelse(idn$date > as.Date("2011-01-01"), 1, 0)

idn <- merge(idn, econ.data, by="date")
price <- idn$price


png("../../write-up/images/diff-price.png", width=800, height=600)
plot(idn$date, idn$s.prop - mys$s.prop, type="l", xlab="", ylab="Difference", col="transparent")
lines(idn$date, v$diff, type="l", xlab="", ylab="Warped difference", col="red")
par(new=TRUE)
plot(date, price/1000, type="l", xlab="", ylab="", axes=FALSE, xaxt="n", yaxt="n")
dev.off()

png("../../write-up/images/price.png", width=800, height=600)
par(mar=c(5,4,4,5)+.1)
plot(date, price, type="l", xlab="", ylab="Palm price")
par(new=TRUE)
plot(date, idn$idn.exch, type="l", xlab="", ylab="", axes=FALSE, xaxt="n", yaxt="n", col="transparent", lty=2)
axis(4)
mtext("IDN exchange rate",side=4,line=3)
dev.off()

png("../../write-up/images/price-exch.png", width=800, height=600)
par(mar=c(5,4,4,5)+.1)
plot(date, price, type="l", xlab="", ylab="Palm price")
par(new=TRUE)
plot(date, idn$idn.exch.y, type="l", xlab="", ylab="", axes=FALSE, xaxt="n", yaxt="n", col="red", lty=2)
axis(4)
mtext("exchange rate",side=4,line=3)
dev.off()

exch.ratio <- idn$idn.exch / idn$mys.exch

summary(lm(v$diff ~ price*post + exch.ratio))

summary(lm(v$diff[1:60] ~ price[1:60]))
summary(lm(v$diff[61:109] ~ price[61:109]))


price <- SMA(idn$price, 24)
plot(price, v$diff, col="transparent")
points(price[1:60], v$diff[1:60])
points(price[61:109], v$diff[61:109], col="red")
m1 <- lm(v$diff[1:60] ~ price[1:60])
lines(price[23:60], m1$fitted.values)
m2 <- lm(v$diff[61:109] ~ price[61:109])
lines(price[61:109], m2$fitted.values)
summary(lm(v$diff ~ price*post + exch.ratio))
