library(TTR)
library(reshape)
library(foreign)
library(ggplot2)
source("clean-econ.R")
source("utils.R")

base.dir <- "../../data/processed/empirical-out"

## Read in the characteristics of the land for all observed hits,
## noting that there is an extraneous index variable in the first
## column of the raw CSV file.
land.data <- read.csv("../../data/raw/clean-resamp.csv")
land.data <- land.data[ ,-1]
names(land.data) <- c("slope", "accum", "elev", "h", "v", "s", "l")

## Supporting functions


land.characteristics <- function(df) {
  ## Accepts a data frame from the new.cluster function, and returns a
  ## list of characteristics associated with the old and new clusters
  ## in that period.
  X <- merge(df, land.data, by=c("h", "v", "s", "l"))
  X <- X[X$new.bin == 1, c("new.cluster", "slope", "accum", "elev")]
  X.new <- X[X$new.cluster == 1,]
  X.old <- X[X$new.cluster == 0,]
  slope <- aggregate(X[["slope"]], by=list(X[["new.cluster"]]), FUN=mean)
  elev <- aggregate(X[["elev"]], by=list(X[["new.cluster"]]), FUN=mean)
  accum <- aggregate(X[["accum"]], by=list(X[["new.cluster"]]), FUN=mean)
  list(old.elev = elev$x[1], new.elev = elev$x[2],
       old.slope = slope$x[1], new.slope = slope$x[2],
       old.accum = accum$x[1], new.accum = accum$x[2])
}

collect.stats <- function(interval.num, iso, data.dir = base.dir) {
  ## Create a "short" data frame with the number of hits in new
  ## clusters and old clusters, as well as the total number of hits in
  ## the 16-day inverval.
  merged <- new.hits(interval.num, iso, base = data.dir)
  x <- new.cluster(merged)

  ## remove the 5 largest clusters for each time period; take them out
  ## of the analysis
  screen.sizes <- tail(sort(unique(x[["clcount"]])), 1)
  print(screen.sizes)
  x <- x[!(x[["clcount"]] %in% screen.sizes), ]
  
  land <- land.characteristics(x)
  new <- nrow(x[x$new.bin == 1 & x$new.cluster == 1, ])
  old <- nrow(x[x$new.bin == 1 & x$new.cluster == 0, ])
  total <- nrow(x[x$new.bin == 1, ])
  data.frame(new = new, old = old, total = total,
             old.slope = land$old.slope, new.slope = land$new.slope,
             old.elev = land$old.elev, new.elev = land$new.elev,
             old.accum = land$old.accum, new.accum = land$new.accum)
}

compiled.hits <- function(iso, idx.seq, data.dir = base.dir) {
  ## returns a data frame for the supplied iso code and the index
  ## sequence of new, old, and total hits
  x <- lapply(idx.seq, function(x) {collect.stats(x, iso, data.dir)})
  mat <- do.call(rbind, x)
  prop <- mat$new / mat$total
  smoothed.prop <- SMA(prop)
  data.frame(date=forma.date(idx.seq), mat, prop = prop, s.prop = smoothed.prop)
}


## Count deforestation by cluster type.  This step takes a while,
## maybe 5-10 minutes.
mys <- compiled.hits("mys", 2:155)
idn <- compiled.hits("idn", 2:155)

## Append the MYS and IDN data into a single data frame, and screen
## out early years for graphing
full.data <- rbind(data.frame(mys, cntry="mys"), data.frame(idn, cntry="idn"))
save(full.data, file="../../data/processed/cluster-count-01.Rdata")
