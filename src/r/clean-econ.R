library(foreign)
library(ggplot2)
library(gdata)
library(zoo)

## Set base directory that contains the economic data

data.dir <- "../../data/raw/"

## Supporting functions

expand.date <- function(x) {
  ## Accepts a string of the form 05/2009 and returns a date object,
  ## expanding the time series to 16-day resolution; used for exchange
  ## rate cleaning
  dates <- c(paste("01/", x, sep=""), paste("15/", x, sep=""))
  as.Date(dates, "%d/%m/%Y")
}

annual.intervals <- function(year) {
  ## Creates a full set of FORMA dates for a year: starting with Jan
  ## 01, and incrementing 16 days until the end of the year
  init.str <- paste(year, "-01-01", sep="")
  seq(as.Date(init.str), length.out = 23, by="16 days")
}

forma.date <- function(forma.pd) {
  ## Convert forma index to the date period; can accept a sequence of
  ## indices.
  max.year <- max(ceiling(forma.pd/23) + 2005)
  full <- do.call(c, lapply(2005:max.year, annual.intervals))
  full[forma.pd + 23]
}

daily.interpolation <- function(df, var.name) {
  ## Spline interpolation of a variable var.name in a data frame that
  ## includes a variable date to daily variable.
  x <- data.frame(date=seq(min(df$date), max(df$date), by="1 day"))
  expanded <- merge(x, df, by=c("date"), all.x = TRUE)
  for (var in var.name) {
    expanded[[var]] <- na.spline(expanded[[var]])
  }
  expanded
}

## Exchange rates from Bank of Indonesia (http://goo.gl/DNrgN)

## Expand exchange rate data to 16-day resolution from monthly
## resolution.
data <- read.csv(file.path(data.dir, "exchange.csv"))
names(data) <- c("date", "exch.rate")

## Expand dates and exchange rate values, binding them into a data
## frame
new.date <- sort(expand.date(data$date))
new.val  <- expand.grid(c(1,2), data$exch.rate)[, 2]
exch.rate <- data.frame(date = new.date, rate = new.val)

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

## Interpolate economic data to align properly with the FORMA data

## Create data frame of daily values for palm price and exchange rate
econ.data <- merge(palm.price, exch.rate, by=c("date"))
econ.data <- daily.interpolation(econ.data, var.name=c("price", "rate"))

## Graph exchange rates
png("../../write-up/images/idn-exchrate.png")
g <- ggplot(data=econ.data, aes(x=date, y=rate)) + geom_line()
(g <- g + xlab("") + ylab("$/Rp exchange rate"))
dev.off()

## Graph palm price
png("../../write-up/images/palm-price.png")
g <- ggplot(data=econ.data, aes(x=date, y=price)) + geom_line()
(g <- g + xlab("") + ylab("$/ton"))
dev.off()

