library(dtw)
library(ggplot2)
library(TTR)
library(mFilter)
source("clean-econ.R")
source("utils.R")

load("../../data/processed/cluster-count-01.Rdata")

## Create binary variables and screen out early data
data <- full.data[get.year(full.data$date) >= 2008, ]
data$cntry <- ifelse(data$cntry == "mys", 0, 1)
data$post <- ifelse(data$date < as.Date("2011-01-01"), 0, 1)

## Merge economic data
data <- merge(data, econ.data, by=c("date"))
idn.data <- data[data$cntry == 1, ]

ma.len <- 10
i <- 1
res.len <- nrow(idn.data) - ma.len
idn.data$res <- NA
for (i in 1:res.len) {
  X <- cbind(1, idn.data$price[i:(i+ma.len)])
  y <- idn.data$s.prop[i:(i+ma.len)]
  beta <- solve(t(X) %*% X) %*% t(X) %*% y
  idn.data$res[i+ma.len] <- beta[2]
}


idn.data$s.price <- hpfilter(idn.data$price, freq=100)$trend
b <- lm(s.prop ~ 1 + s.price + idn.exch + s.price * post, data=idn.data)$coefficients

idn.data$res <- idn.data$s.prop - (b["(Intercept)"] + idn.data$s.price * b["s.price"])
ggplot(idn.data, aes(x = date, y = res)) + geom_line() + geom_smooth(method = "lm")
