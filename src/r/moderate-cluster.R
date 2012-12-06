library(ggplot2)
library(reshape)
library(plm)
library(foreign)
library(mFilter)
library(TTR)
source("clean-econ.R")
source("utils.R")

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

## Function that returns a list with the total deforestation rate over
## time for the supplied country iso code, indexed by how many of the
## largest superclusters to screen out.

screened.rates <- function(iso, rank.screen) {
  ## Returns the total deforestation rate for the supplied country
  ## (iso code) and the number of the largest super clusters to screen
  ## out, noting that the "largest" clusters are identified by the
  ## Sept 13, 2012, or the final period of analysis.
  pixel.idx <- screen.super(iso, rank.screen)
  new.count <- lapply(1:155, function(x) {count.hits(x, iso, pixel.idx)})
  new.rate  <- diff(do.call(c, new.count))
  return(new.rate)
}

compile.rates <- function(iso, rank.seq) {
  ## Returns a list of the total deforestation rates, indexed by the
  ## number of superclusters screened out.  Each item of the list is
  ## matched to the date object for easy merges with other lists.
  date.seq <- forma.date(2:155)
  rates <- lapply(rank.seq, function(x) {screened.rates(iso, x)})
  for (i in 1:length(rates)) {
    rates[[i]] <- data.frame(rate = rates[[i]], date = date.seq)
  }
  return(rates)
}

## This part takes a long time
## TODO: docs
screen.seq <- 10
compiled.idn <- compile.rates("idn", screen.seq)
compiled.mys <- compile.rates("mys", screen.seq)

merge.rates <- function(idn.rates, mys.rates, begin.year = 2008) {
  ## TODO: docs
  merged <- list()
  for (i in 1:length(idn.rates)) {
    merged[[i]] <- merge(idn.rates[[i]], mys.rates[[i]], by="date")
    names(merged[[i]]) <- c("date", "idn.rate", "mys.rate")
    year <- get.year(merged[[i]][["date"]])
    merged[[i]] <- merged[[i]][year >= begin.year,]
  }
  return(merged)
}

## TODO: docs
anim.data <- merge.rates(compiled.idn, compiled.mys)

## TODO: docs
for (i in screen.seq) {
  png(paste("../../write-up/images/screen", i, ".png", sep=""), width=800, height=600)
  df <- anim.data[[i]]
  title <- paste(i, "supercluster(s) screened")

  ## TODO: docs
  plot(date, df$idn.rate, type="l", main=title, xlab="",
       ylab="Total deforestation rate", ylim=c(200,1100))
  lines(date, df$mys.rate, type="l", col="red", lty=2)

  ## TODO: docs
  polygon(c(date[post==1], rev(date[post==1])),
        c(df$idn.rate[post==1], rev(df$mys.rate[post==1])), col="darkgrey")
  idx <- which((df$idn.rate < df$mys.rate) & post == 1)
  polygon(c(date[idx], rev(date[idx])),
          c(df$idn.rate[idx], rev(df$mys.rate[idx])), col="skyblue")
  
  dev.off()
}

## Create data from screening out top 10 largest superclusters
df <- anim.data[[1]]
data <- melt(df, id=c("date"))
names(data) <- c("date", "cntry", "rate")
data <- merge(data, sub.econ, by=c("date"))
data$cntry <- ifelse(data$cntry == "mys.rate", 0, 1)
data$post <- ifelse(data$date < as.Date("2011-01-01"), 0, 1)
data$price <- data$price/100

m1 <- lm(rate ~ price, data = data)
m2 <- lm(rate ~ price + I(price^2), data = data)
m3 <- lm(rate ~ price + cntry*post, data = data)
m4 <- lm(rate ~ price + I(price^2) + cntry*post, data = data)

data$post <- ifelse(data$date < as.Date("2010-05-20"), 0, 1)
m1 <- lm(rate ~ 1 + cntry*post + price + I(price^2), data = data)

data$post <- ifelse(data$date < as.Date("2011-01-01"), 0, 1)
m2 <- lm(rate ~ 1 + cntry*post + price + I(price^2), data = data)

data$post <- ifelse(data$date < as.Date("2011-05-20"), 0, 1)
m3 <- lm(rate ~ 1 + cntry*post + price + I(price^2), data = data)

summary(m1)
summary(m2)
summary(m3)

create.table(list(m1, m2, m3), "screened-rates.tex")


## post <- lm(diff ~ poly(idx,2), data = rate.df[post==0,])$fitted.values
## pre  <- lm(diff ~ poly(idx,2), data = rate.df[post==1,])$fitted.values

## ## Smooth over the rates with an HP filter, given abrupt changes most
## ## likely due to large areas being cleared in super clusters, which will 
## rate.idn <- hpfilter(rate.idn, freq=2)$trend
## rate.mys <- hpfilter(rate.mys, freq=2)$trend
## rate.diff <- rate.idn - rate.mys

## df <- data.frame(rate.diff = rate.diff, date = date, post = post)

## post <- lm(diff ~ poly(idx,2), data = df[df$idx >= 60,])$fitted.values
## pre  <- lm(diff ~ poly(idx,2), data = df[df$idx < 60,])$fitted.values
## plot(d)
## lines(60:length(d), post, col = "red")
## lines(1:59, pre, col = "red")

## plot(ts.idn - ts.mys)
## plot(SMA(ts.idn - ts.mys)[46:length(ts.idn)])
## plot(SMA(ts.idn)[46:length(ts.idn)])
## lines(SMA(ts.mys))

## old <- 1:60
## new <- 61:109
## old <- data.frame(price=price[old], idn.val=ts.filter.idn[old], mys.val=ts.filter.mys[old])
## new <- data.frame(price=price[new], idn.val=ts.filter.idn[new], mys.val=ts.filter.mys[new])
## m <- lm(idn.val~price, data=old)
## new$predict <- predict(m, new)
## old$predict <- m$fitted.values
## new$resid <- new$idn.val - new$predict
## old$diff <- old$idn.val - old$mys.val 
## new$diff <- new$idn.val - new$mys.val 
## sd(new$resid)
## mean(new$resid)

## plot(c(old$price, new$price), c(old$idn.val, new$idn.val), col="transparent",
##      xlab="Palm oil price ($/ton)", ylab="Indonesian deforestation rate")
## points(old$price, old$idn.val)
## points(new$price, new$idn.val, col="red")
## lines(c(old$price, new$price), c(old$predict, new$predict))

## m <- lm(diff~price, data=old)
## new$diff.predict <- predict(m, new)
## old$diff.predict <- m$fitted.values
## new$diff.resid <- new$diff - new$diff.predict
## plot(c(old$price, new$price), c(old$diff, new$diff), col="transparent",
##      xlab="Palm oil price ($/ton)", ylab="Difference between IDN and MYS rates")
## points(old$price, old$diff)
## points(new$price, new$diff, col="red")
## sd(new$diff.resid)
## mean(new$diff.resid)
## lines(c(old$price, new$price), c(old$diff.predict, new$diff.predict))

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

sub.data$cntry <- toupper(sub.data$cntry)
g <- ggplot(data=sub.data, aes(x=date, y=s.prop, colour=cntry)) + geom_line()
g <- g + xlab("") + ylab("Proportion of deforestation in new clusters") +
  opts(panel.background = theme_blank(), legend.position = "none")
g <- policy.bars(g)
ggsave("../../write-up/images/ggplot-prop.png", g, width=8, height=4, dpi=200)

df <- anim.data[[1]]
data <- melt(df, id=c("date"))
names(data) <- c("date", "cntry", "rate")
data <- merge(data, sub.econ, by=c("date"))
data$cntry <- ifelse(data$cntry == "mys.rate", "MYS", "IDN")


g <- ggplot(data=data, aes(x=date, y=rate, colour=cntry)) + geom_line()
g <- g + xlab("") + ylab("Total deforestation rate") +
  opts(panel.background = theme_blank(), legend.position = "none")
g <- policy.bars(g)
ggsave("../../write-up/images/ggplot-total.png", g, width=8, height=4, dpi=200)

g <- ggplot(data=sub.data[sub.data$cntry == "MYS",], aes(x=date, y=price)) + geom_line()
g <- g + xlab("") + ylab("Palm Oil Price ($/ton)") +
  opts(panel.background = theme_blank(), legend.position = "none")
g <- policy.bars(g)
ggsave("../../write-up/images/price.png", g, width=8, height=4, dpi=200)
