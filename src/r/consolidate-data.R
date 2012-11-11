library(reshape)
library(foreign)

base.dir <- "../../data/staging/empirical-out"

read.cluster <- function(interval.num, iso, base = base.dir) {
  ## Accepts an interval number and reads in the Stata file to return
  ## the data frame of cluster counts associated with the supplied
  ## interval
  fname <- paste(iso, "-clcount-", interval.num, ".dta", sep="")
  read.dta(file.path(base, fname))
}

new.hits <- function(interval.num, iso, base = base.dir) {
  ## Adds a column to the new data, indicating whether the pixel was a
  ## new hit (1) or an old hit (0), noting that the input data in the
  ## base directory is cumulative and monotonic -- once a pixel is
  ## called, it remains that way forever after.

  new.data <- read.cluster(interval.num, iso)
  old.data <- read.cluster(interval.num - 1, iso)

  ## All data in new.data is retained, even if there is no match in
  ## old.data; if there is no match, there will not be a period when
  ## it was first called associated with old.data set
  merged <- merge(new.data, old.data, by=c("h", "v", "s", "l"), sort = FALSE, all.x = TRUE)
  new.hit <- is.na(merged[["pd.y"]])
  merged$new <- ifelse(new.hit, 1, 0)
  merged <- merged[ , c(1:9, 15)]
  names(merged) <- c("h", "v", "s", "l", "lat", "lon", "pd", "cid", "clcount", "new.bin")
  merged
}

merged <- new.hits(120, "mys")

a <- merged[merged$new == 1 & merged$pd.x == 120,]
print(dim(a))

## x <- read.csv("../../resources/idn-hits.csv")
## x <- read.dta("~/Dropbox/idn_hits.dta")

