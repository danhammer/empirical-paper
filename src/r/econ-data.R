
crude.oil <- read.csv('http://www.quandl.com/api/v1/datasets/IMF/POILAPSP_INDEX.csv?&trim_start=1980-01-31&trim_end=2013-01-31&sort_order=desc', colClasses=c('Date'='Date'))
farm.prices <- read.csv('http://www.quandl.com/api/v1/datasets/CANSIM/002_0043_1_200.csv?&trim_start=1985-01-31&trim_end=2012-09-30&sort_order=desc', colClasses=c('Date'='Date'))
palm.oil <- read.csv('http://www.quandl.com/api/v1/datasets/INDEXMUNDI/COMMODITY_PALMOIL.csv?&trim_start=1983-01-31&trim_end=2013-01-31&sort_order=desc', colClasses=c('Month'='Date'))
silver <- read.csv('http://www.quandl.com/api/v1/datasets/INDEXMUNDI/COMMODITY_SILVER.csv?&trim_start=1983-01-31&trim_end=2013-01-31&sort_order=desc', colClasses=c('Month'='Date'))
copper <- read.csv('http://www.quandl.com/api/v1/datasets/WORLDBANK/WLD_COPPER.csv?&trim_start=1960-01-31&trim_end=2013-01-31&sort_order=desc', colClasses=c('Date'='Date'))
salmon <- read.csv('http://www.quandl.com/api/v1/datasets/INDEXMUNDI/COMMODITY_FISHSALMON.csv?&trim_start=1983-01-31&trim_end=2013-01-31&sort_order=desc', colClasses=c('Month'='Date'))

names(crude.oil) <- c("date", "crude")
names(farm.prices) <- c("date", "farm")
names(palm.oil) <- c("date", "palm")
names(silver) <- c("date", "silver")
names(copper) <- c("date", "copper")
names(salmon) <- c("date", "salmon")

x <- merge(crude.oil, farm.prices, by = c("date"))
x <- merge(x, palm.oil, by = c("date"))
x <- merge(x, silver, by = c("date"))
x <- merge(x, copper, by = c("date"))
x <- merge(x, salmon, by = c("date"))
x <- x[x$date > as.Date("2007-12-31"), ]
x$post <- ifelse(x$date > as.Date("2011-05-12"), 1, 0)


diffx <- data.frame(sapply(names(x), function(i) {x[[i]] <- c(NA, diff(x[[i]]))}))

summary(lm(palm ~ 1 + crude + silver + copper, data = x))
summary(lm(palm ~ 1 + crude + silver + copper, data = diffx))

summary(lm(palm ~ 1 + crude + silver + copper + post, data = x))
summary(lm(palm ~ 1 + crude + silver + copper +  post, data = diffx))
