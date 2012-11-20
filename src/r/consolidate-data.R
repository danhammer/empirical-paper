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
  screen.sizes <- tail(sort(unique(x[["clcount"]])), 5)
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
mys <- compiled.hits("mys", 40:155)
idn <- compiled.hits("idn", 40:155)

## Append the MYS and IDN data into a single data frame, and screen
## out early years for graphing
full.data <- rbind(data.frame(mys, cntry="mys"), data.frame(idn, cntry="idn"))
save(full.data, file="../../data/processed/cluster-count-01.Rdata")
sub.data <- full.data[get.year(full.data$date) >= 2008,]

## Graph total rates
png("../../write-up/images/total-rate.png", width=600, height=400)
g <- ggplot(data = sub.data, aes(x = date, y = total, colour = cntry)) + geom_line()
(g <- g + xlab("") + ylab(""))
dev.off()

## Graph smoothed proportion of deforestation in new clearing
png("../../write-up/images/smoothed-prop.png", width=600, height=400)
g <- ggplot(data = sub.data, aes(x = date, y = s.prop, colour = cntry)) + geom_line()
(g <- g + xlab("") + ylab(""))
dev.off()

## graph land characteristics
graph.land <- function(iso, land.type, out.name = FALSE) {
  if (out.name == FALSE) {
    name <- paste(iso, "-", land.type, ".png", sep="")
    f <- file.path("../../write-up/images", name)
  }
  new <- paste("new.", land.type, sep=""); old <- paste("old.", land.type, sep="")
  g.data <- sub.data[sub.data$cntry == iso, c("date", new, old)]
  g.data <- melt(g.data, id="date")
  names(g.data) <- c("date", "cluster.type", "land.char")
  g <- ggplot(data = g.data, aes(x = date, y = land.char, colour = cluster.type)) + geom_line()
  ggsave(f, g)
  return(g)
}

## Graph slopes
graph.land("idn", "slope")
graph.land("mys", "slope")

## Graph water accumulation
graph.land("idn", "accum")
graph.land("mys", "accum")

## Graph elevation
graph.land("idn", "elev")
graph.land("mys", "elev")

