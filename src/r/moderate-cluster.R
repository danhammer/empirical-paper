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

screen.super <- function(iso, screen.rank) {
  ## Identify the X largest superclusters as identified in the last
  ## period of analysis, here indexed by forma.date(155) =>
  ## "2012-09-13". Returns a data frame with the pixel-level
  ## identifiers of any pixels that DO NOT end up in the X largest
  ## super clusters
  final <- read.cluster(155, iso)
  agg <- aggregate(final$cl_155, by=list(final$count_155), FUN=mean)
  super.ids <- tail(agg$x, screen.rank)
  final[!(final$cl_155 %in% super.ids), c("h", "v", "s", "l")]
}

count.hits <- function(interval.num, iso, screen.df) {
  ## Count only the deforestation pixels that are NOT in the largest X
  ## clusters in the final time period. The data frame screen.df
  ## should be the result of the screen.super() function
  data <- read.cluster(interval.num, iso)
  new.data <- merge(data, screen.df, by=c("h", "v", "s", "l"))
  nrow(new.data)
}

## Create a data frame with the economic data for only the dates
load("../../data/processed/cluster-count-01.Rdata")
load("../../data/processed/snap-econ.Rdata")
sub.data <- full.data[get.year(full.data$date) >= 2008,]
sub.econ <- snap.econ[get.year(snap.econ$date) >= 2008,]

## Convenient labels for IDN and MYS data, separated
idn <- sub.data[sub.data$cntry == "idn", ]
mys <- sub.data[sub.data$cntry == "mys", ]

## Create individual economic data objects
date  <- sub.econ[["date"]]
price <- sub.econ[["price"]]
post  <- ifelse(date > as.Date("2011-01-01"), 1, 0)

## Data frames of the pixel-level identifiers that should be kept in
## the analysis, after screening out the largest five super clusters.
idn.screen <- screen.super("idn", 5)
mys.screen <- screen.super("mys", 5)

## Lists that contain the counts of deforestation hits that occur in
## each interval, but not in the top 5 largest super-clusters
count.idn <- lapply(1:155, function(x) {count.hits(x, "idn", idn.screen)})
count.mys <- lapply(1:155, function(x) {count.hits(x, "mys", mys.screen)})

## Collapse the lists into a column that contains the rates, or
## differences between each listand; should have length 154 (one less
## than the number of total intervals)
rate.idn <- diff(do.call(c, count.idn))
rate.mys <- diff(do.call(c, count.mys))
rate.dates <- forma.date(2:155)
rate.df <- data.frame(rate.idn, rate.mys, date = rate.dates)

## Smooth over the rates with an HP filter, given abrupt changes most
## likely due to large areas being cleared in super clusters, which will 
rate.idn <- hpfilter(rate.idn, freq=2)$trend
rate.mys <- hpfilter(rate.mys, freq=2)$trend
rate.diff <- rate.idn - rate.mys

df <- data.frame(rate.diff = rate.diff, date = date, post = post)

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
