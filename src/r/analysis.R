source("clean-econ.R")
source("utils.R")

## retrieve cluster count data as data frame, full.data
load("../../data/processed/cluster-count.Rdata")

data <- full.data[get.year(full.data$date) >= 2008, ]
data$cntry <- ifelse(data$cntry == "mys", 0, 1)
data$post <- ifelse(data$date < as.Date("2011-01-01"), 0, 1)

data <- merge(data, econ.data, by=c("date"))

summary(lm(s.prop ~ 1 + price + cntry*post, data = data))
summary(lm(s.prop ~ 1 + idn.exch + price + price*cntry*post, data = data))

summary(lm(total ~ 1 + price + price*cntry*post, data = data))
summary(lm(total ~ 1 + price + idn.exch, data = data))

