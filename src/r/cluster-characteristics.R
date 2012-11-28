library(foreign)

base.dir <- "../../data/processed/empirical-out"

read.cluster <- function(interval.num, iso, base = base.dir) {
  ## Accepts an interval number and reads in the Stata file to return
  ## the data frame of cluster counts associated with the supplied
  ## interval
  fname <- paste(iso, "-clcount-", interval.num, ".dta", sep="")
  read.dta(file.path(base, fname))
}

pixel.data <- read.cluster(155, "idn")
## biggest.cluster <- pixel.data[d$cl_155 == 2185, ]
## plot(biggest.cluster$lon, biggest.cluster$lat)

land.data <- read.csv("../../data/raw/clean-resamp.csv")
land.data <- land.data[ ,-1]
names(land.data) <- c("slope", "accum", "elev", "h", "v", "s", "l")

pixel.data <- merge(pixel.data, land.data, by=c("h", "v", "s", "l"))
pixel.data <- pixel.data[pixel.data$count_155 >= 50, ]
pixel.data <- pixel.data[pixel.data$pd >= 46, ]

## land.char <- cluster[,c("slope", "accum", "elev")]
## agg <- aggregate(land.char, by=list(cluster$pd), FUN=mean)

slope.trend <- function(cluster.num) {
  d <- pixel.data[pixel.data$cl_155 == cluster.num, c("pd", "slope")]
  mod <- lm(slope ~ pd + I(pd^2), data=d)
  tstats <- coef(mod) / sqrt(diag(vcov(mod)))
  tstats[["pd"]]
}

v <- unique(pixel.data$cl_155)

x <- lapply(v, slope.trend)
y <- do.call(c, x)
hist(y, breaks=40)
