library(dtw)
library(plm)
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
data$pd <- ifelse(data$date > as.Date("2010-06-22") & data$date < as.Date("2011-01-01"), 1, 0)
data$pd <- ifelse(data$date >= as.Date("2011-01-01") & data$date < as.Date("2011-05-22"), 2, data$pd)
data$pd <- ifelse(data$date > as.Date("2011-05-22"), 3, data$pd)

## Merge economic data
data <- merge(data, econ.data, by=c("date"))
data <- pdata.frame(data, c("cntry", "date"))
data$lag <- lag(data$price, k=5)

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


idn.data <- na.omit(idn.data)
## idn.data$s.price <- hpfilter(idn.data$lag, freq=100)$trend
idn.data$s.price <- idn.data$price
idn.data$date <- as.Date(idn.data$date)
summary(lm(s.prop ~ 1 + idn.exch + date + lag * post, data=idn.data))
b <- lm(s.prop ~ 1 + idn.exch + lag * post, data=idn.data)$coefficients

idn.data$res <- idn.data$s.prop - (b["(Intercept)"] + idn.data$s.price * b["lag"])

pre <- idn.data[idn.data$post == 0,]
post <- idn.data[idn.data$post == 1,]

post.poly <- lm(res ~ ns(date, 4), data=post)$fitted.values
pre.poly <- lm(res ~ ns(date, 4), data=pre)$fitted.values
idn.data$poly <- c(pre.poly, post.poly)

(g <- ggplot(idn.data, aes(x = date, y = res, group=pd)) + geom_point())
g + stat_smooth(aes(col=pd))

