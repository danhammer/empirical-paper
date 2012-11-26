library(foreign)
library(mFilter)
library(TTR)
source("clean-econ.R")

base.dir <- "../../data/processed/empirical-out"

read.cluster <- function(interval.num, iso, base = base.dir) {
  ## Accepts an interval number and reads in the Stata file to return
  ## the data frame of cluster counts associated with the supplied
  ## interval
  fname <- paste(iso, "-clcount-", interval.num, ".dta", sep="")
  read.dta(file.path(base, fname))
}

count.hits <- function(interval.num, iso) {
  data <- read.cluster(interval.num, iso)
  scr.sizes <- tail(sort(unique(data[,9])), 5)
  data <- data[!(data[,9] %in% scr.sizes),]
  nrow(data)
}

load("../../data/processed/cluster-count-01.Rdata")
sub.data <- full.data[get.year(full.data$date) >= 2008,]
idn <- sub.data[sub.data$cntry == "idn", ]
mys <- sub.data[sub.data$cntry == "mys", ]
idn <- merge(idn, econ.data, by="date")
mys <- merge(mys, econ.data, by="date")
price <- idn$price

a <- lapply(1:155, function(x) {count.hits(x, "idn")})
b <- lapply(1:155, function(x) {count.hits(x, "mys")})
ts.idn <- diff(do.call(c, a))
ts.mys <- diff(do.call(c, b))
ts.filter.idn <- hpfilter(ts.idn[46:length(ts.idn)], freq=2)$trend
ts.filter.mys <- hpfilter(ts.mys[46:length(ts.mys)], freq=2)$trend


d <- ts.idn - ts.mys
d <- ts.filter.idn - ts.filter.mys
## d <- d[3:length(d)]

df <- data.frame(diff = d, idx = 1:length(d))
post <- lm(diff ~ poly(idx,2), data = df[df$idx >= 60,])$fitted.values
pre  <- lm(diff ~ poly(idx,2), data = df[df$idx < 60,])$fitted.values
plot(d)
lines(60:length(d), post, col = "red")
lines(1:59, pre, col = "red")

## plot(ts.idn - ts.mys)
## plot(SMA(ts.idn - ts.mys)[46:length(ts.idn)])
## plot(SMA(ts.idn)[46:length(ts.idn)])
## lines(SMA(ts.mys))

old <- 1:60
new <- 61:109
old <- data.frame(price=price[old], idn.val=ts.filter.idn[old], mys.val=ts.filter.mys[old])
new <- data.frame(price=price[new], idn.val=ts.filter.idn[new], mys.val=ts.filter.mys[new])
m <- lm(idn.val~price, data=old)
new$predict <- predict(m, new)
old$predict <- m$fitted.values
new$resid <- new$idn.val - new$predict
old$diff <- old$idn.val - old$mys.val 
new$diff <- new$idn.val - new$mys.val 
sd(new$resid)
mean(new$resid)

plot(c(old$price, new$price), c(old$idn.val, new$idn.val), col="transparent",
     xlab="Palm oil price ($/ton)", ylab="Indonesian deforestation rate")
points(old$price, old$idn.val)
points(new$price, new$idn.val, col="red")
lines(c(old$price, new$price), c(old$predict, new$predict))

m <- lm(diff~price, data=old)
new$diff.predict <- predict(m, new)
old$diff.predict <- m$fitted.values
new$diff.resid <- new$diff - new$diff.predict
plot(c(old$price, new$price), c(old$diff, new$diff), col="transparent",
     xlab="Palm oil price ($/ton)", ylab="Difference between IDN and MYS rates")
points(old$price, old$diff)
points(new$price, new$diff, col="red")
sd(new$diff.resid)
mean(new$diff.resid)
lines(c(old$price, new$price), c(old$diff.predict, new$diff.predict))
