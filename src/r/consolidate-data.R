library(TTR)
library(reshape)
library(foreign)

base.dir <- "../../data/staging/empirical-out"

## Supporting functions

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

new.cluster <- function(df) {
  ## Accepts a data frame that is the output from new.hits() and
  ## returns the data frame with a new column at the cluster level
  ## indicating whether that cluster existed in the previous period or
  ## not.  A 1 indicates that the cluster is new, and a 0 indicates
  ## that it is old.
  y <- aggregate(df$new.bin, list(df$cid), min)
  names(y) <- c("cid", "new.cluster")
  merge(df, y, by=("cid"))
}

collect.stats <- function(interval.num, iso, data.dir = base.dir) {
  ## Create a "short" data frame with the number of hits in new
  ## clusters and old clusters, as well as the total number of hits in
  ## the 16-day inverval.
  merged <- new.hits(interval.num, iso, base = data.dir)
  x <- new.cluster(merged)
  new <- nrow(x[x$new.bin == 1 & x$new.cluster == 1, ])
  old <- nrow(x[x$new.bin == 1 & x$new.cluster == 0, ])
  total <- nrow(x[x$new.bin == 1, ])
  data.frame(new = new, old = old, total = total)
}

compiled.hits <- function(iso, idx.seq, data.dir = base.dir) {
  ## returns a data frame for the supplied iso code and the index
  ## sequence of new, old, and total hits
  x <- lapply(idx.seq, function(x) {collect.stats(x, iso, data.dir)})
  mat <- do.call(rbind, x)
  prop <- mat$new / mat$total
  smoothed <- SMA(prop)
  data.frame(date=forma.date(idx.seq), mat, prop = prop, smoothed = smoothed)
}

mys <- compiled.hits("mys", 2:155)
idn <- compiled.hits("idn", 2:108)

get.year <- function(date) {as.numeric(format(date, "%Y"))}

(g <- ggplot(data=mys, aes(x=date, y=smoothed)) + geom_line())
