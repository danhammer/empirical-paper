library(foreign)

date.data <- read.csv("../../write-up/data/raw/dates.csv", header = FALSE)

local.dir <- "/home/dan/local-data/"

d <- read.dta("/home/dan/local-data/empirical-out-9/idn-clcount-1.dta")

res
length(d[d[,4]<=2,4])
