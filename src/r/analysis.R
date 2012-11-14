library(texreg)
source("clean-econ.R")
source("utils.R")

## retrieve cluster count data as data frame, full.data
load("../../data/processed/cluster-count.Rdata")

data <- full.data[get.year(full.data$date) >= 2008, ]
data$cntry <- ifelse(data$cntry == "mys", 0, 1)
data$post <- ifelse(data$date < as.Date("2011-01-01"), 0, 1)

data <- merge(data, econ.data, by=c("date"))

data$s.prop <- data$s.prop * 100
data$price <- data$price / 1000
data$idn.exch <- data$idn.exch * 1000

m1 <- lm(s.prop ~ 1 + price + cntry*post, data = data)
m2 <- lm(s.prop ~ 1 + idn.exch + price + cntry*post, data = data)
m3 <- lm(s.prop ~ 1 + price*cntry*post, data = data)
m4 <- lm(s.prop ~ 1 + idn.exch + price*cntry*post, data = data)

table.string <- texreg(list(m1, m2, m3, m4),
                       model.names=c("(1)", "(2)", "(3)", "(4)"),
                       digits=3,
                       table=FALSE,
                       use.packages=FALSE)
out <- capture.output(cat(table.string))
cat(out, file="../../write-up/tables/prop-res.tex", sep="\n")

m1 <- lm(total ~ 1 + cntry*post, data = data)
m2 <- lm(total ~ 1 + price + cntry*post, data = data)
m3 <- lm(total ~ 1 + idn.exch + price + cntry*post, data = data)

table.string <- texreg(list(m1, m2, m3),
                       model.names=c("(1)", "(2)", "(3)"),
                       digits=3,
                       table=FALSE,
                       use.packages=FALSE)
out <- capture.output(cat(table.string))
cat(out, file="../../write-up/tables/total-res.tex", sep="\n")
