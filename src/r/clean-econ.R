library(foreign)
library(ggplot2)
library(gdata)

data.dir <- "../../data/raw/"

## Exchange rates from Bank of Indonesia (http://goo.gl/DNrgN)

expand.date <- function(x) {
  ## Accepts a string of the form 05/2009 and returns a date object,
  ## expanding the time series to 16-day resolution; used for exchange
  ## rate cleaning
  dates <- c(paste("01/", x, sep=""), paste("15/", x, sep=""))
  as.Date(dates, "%d/%m/%Y")
}

## Expand exchange rate data to 16-day resolution from monthly
## resolution.
data <- read.csv(file.path(data.dir, "exchange.csv"))
names(data) <- c("date", "exch.rate")

## Expand dates and exchange rate values, binding them into a data
## frame
new.date <- sort(expand.date(data$date))
new.val  <- expand.grid(c(1,2), data$exch.rate)[, 2]
exch.rate <- data.frame(date = new.date, rate = new.val)

## Graph exchange rates
png("../../write-up/images/idn-exchrate.png")
g <- ggplot(data=exch.rate, aes(x=date, y=rate)) + geom_line()
(g <- g + xlab("") + ylab("$/Rp exchange rate"))
dev.off()


## Palm prices from indexmundi

## http://www.indexmundi.com/commodities/?commodity=palm-oil&months=120
## USD per ton

path <- file.path(data.dir, "palmprice.txt")
price.data <- read.table(path, sep=";", skip=1)
names(price.data) <- c("date", "price")
price <- as.numeric(gsub(",","", price.data$price))

## Use the expanded date from above
new.price  <- expand.grid(c(1,2), price)[, 2]
palm.price <- data.frame(date = new.date[1:length(new.price)], price = new.price)

## Graph palm price
png("../../write-up/images/palm-price.png")
g <- ggplot(data=palm.price, aes(x=date, y=price)) + geom_line()
(g <- g + xlab("") + ylab("$/ton"))
dev.off()
