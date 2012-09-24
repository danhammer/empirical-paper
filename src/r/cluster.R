source("playground.R")
source("load-gadm.R")

hits <- read.table("/home/dan/Downloads/borneo/part-00000")
names(hits) <- c("lat", "lon", "gadm", "pd")

mys.hits <- hits[hits[["gadm"]] %in% mys.gadm, ]
idn.hits <- hits[hits[["gadm"]] %in% idn.gadm, ]

## screen out most pixels for testing
mys.hits <- mys.hits[sample.int(nrow(mys.hits), 3000), ]
idn.hits <- idn.hits[sample.int(nrow(idn.hits), 3000), ]

newClusters <- function(hits, dist.thresh = 0.05, sm.cluster.bound = 2) {
  T <- max(hits[["pd"]])
  res <- rep(-9999, T)
  for (i in 0:T) {
    incre.idx <- hits[["pd"]] <= i
    sub.hits <- hits[incre.idx, ]
    hit.mat <- cbind(sub.hits[["lat"]], sub.hits[["lon"]])
    htree <- hclust(dist(hit.mat, method="euclidean"), method="single")
    cluster.id <- cutree(htree, h=dist.thresh)
    indexed.clusters <- cbind(sub.hits, cluster.id)
    counts <- as.data.frame(table(cluster.id))
    merged <- merge(indexed.clusters, counts, by.x="cluster.id", by.y="cluster.id")
    new.clusters <- merged[merged[["pd"]]==i,"Freq"]
    print(i)
    res[i] <- length(new.clusters[new.clusters <= sm.cluster.bound])
  }
  res
}

mys.res <- newClusters(mys.hits)
idn.res <- newClusters(idn.hits)

sumtrend <- function(res) {
  x1 <- 46:100
  x2 <- 101:T
  y1 <- res[x1]
  y2 <- res[x2]
  ## y2[y2>10] <- 0
  print(summary(lm(y1 ~ 1 + x1)))
  print(summary(lm(y2 ~ 1 + x2)))
}

sumtrend(idn.res)
sumtrend(mys.res)

idn.res <- idn.res[46:146]
mys.res <- mys.res[46:146]

idn.mat <- as.data.frame(cbind(46:146, 1, idn.res, 0))
names(idn.mat) <- c("pd", "cid", "new.clusters", "mora")
idn.mat[idn.mat$pd > 100, "mora"] <- 1

mys.mat <- as.data.frame(cbind(46:146, 0, mys.res, 0))
names(mys.mat) <- c("pd", "cid", "new.clusters", "mora")
mys.mat[mys.mat$pd > 100, "mora"] <- 1

total.mat <- rbind(idn.mat, mys.mat)
model <- lm(new.clusters ~ 1 + pd*cid + pd*mora + mora*cid*pd, data=total.mat)
