library(foreign)
library(ggplot2)

data.dir <- "../../data/raw/"

expand.date <- function(x) {
  ## Accepts a string of the form 05/2009 and returns a date object,
  ## expanding the time series to 16-day resolution
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
