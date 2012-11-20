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
  scr.sizes <- tail(sort(unique(data[,9])), 10)
  data <- data[!(data[,9] %in% scr.sizes),]
  nrow(data)
}


a <- lapply(1:155, function(x) {count.hits(x, "idn")})
b <- lapply(1:155, function(x) {count.hits(x, "mys")})
ts.idn <- diff(do.call(c, a))
ts.mys <- diff(do.call(c, b))
idn <- hpfilter(ts.idn[46:length(ts.idn)], freq=2)$trend
mys <- hpfilter(ts.mys[46:length(ts.mys)], freq=2)$trend


d <- idn - mys
df <- data.frame(diff = d, idx = 1:length(d))
post <- lm(diff ~ poly(idx,8), data = df[df$idx >= 60,])$fitted.values
pre  <- lm(diff ~ poly(idx,8), data = df[df$idx  < 60,])$fitted.values
plot(d)
lines(60:length(d), post, col = "red")
lines(1:59, pre, col = "red")

plot(ts.idn - ts.mys)
plot(SMA(ts.idn - ts.mys)[46:length(ts.idn)])
plot(SMA(ts.idn)[46:length(ts.idn)])
lines(SMA(ts.mys))
