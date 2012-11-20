library(texreg)
source("clean-econ.R")
source("utils.R")

## retrieve cluster count data as data frame, full.data
load("../../data/processed/cluster-count-01.Rdata")

## Create binary variables and screen out early data
data <- full.data[get.year(full.data$date) >= 2008, ]
data$cntry <- ifelse(data$cntry == "mys", 0, 1)
data$post <- ifelse(data$date < as.Date("2011-01-01"), 0, 1)

## Merge economic data
data <- merge(data, econ.data, by=c("date"))

## Transform measures so that the tables do not have so many digits
data$s.prop <- data$s.prop * 100
data$price <- data$price / 1000
data$idn.exch <- data$idn.exch * 1000

create.table <- function(model.list, file.name) {
  ## Create a tex fragment of a standardized table, saving to the
  ## supplied file name in the tables directory
  path <- file.path("../../write-up/tables", file.name)
  table.string <- texreg(model.list, digits=3, table=FALSE, use.packages=FALSE)
  out <- capture.output(cat(table.string))
  cat(out, file = path, sep="\n")
}

neg.cntry <- 1 - data$cntry
## Results for proportion variables
m1 <- lm(s.prop ~ 1 + price + cntry*post, data = data)
m2 <- lm(s.prop ~ 1 + idn.exch + price + cntry*post, data = data)
m3 <- lm(s.prop ~ 1 + price*cntry*post, data = data)
m4 <- lm(s.prop ~ 1 + idn.exch*cntry - idn.exch + mys.exch*neg.cntry - neg.cntry - mys.exch + price*cntry*post, data = data)

create.table(list(m1, m2, m3, m4), "prop-res.tex")

## Results for overall trends
m1 <- lm(total ~ 1 + date + post, data = data)
m2 <- lm(total ~ 1 + cntry*post, data = data)
m3 <- lm(total ~ 1 + price*post, data = data)
m4 <- lm(total ~ 1 + price*cntry*post, data = data)

create.table(list(m1, m2, m3, m4), "total-res.tex")

## Check to see if the distributions of the land characteristics are
## significantly different from one another, split by type of clearing
## activity.


