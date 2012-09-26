os <- Sys.info()["sysname"]
if (os != "Linux") {
  setwd("C:\\Users\\danhammer\\Dropbox\\github\\danhammer\\empirical-paper\\src\\r")
}  

source("playground.R")
source("load-gadm.R")

hits <- read.table("../../resources/part-00000")
names(hits) <- c("lat", "lon", "gadm", "pd")

mys.hits <- hits[hits[["gadm"]] %in% mys.gadm, ]
idn.hits <- hits[hits[["gadm"]] %in% idn.gadm, ]

## screen out most pixels for testing
mys.hits <- mys.hits[sample.int(nrow(mys.hits), 200), ]
idn.hits <- idn.hits[sample.int(nrow(idn.hits), 200), ]

## define relevant moratorium period
pre.pd <- 46:115
mora.pd <- 116:147
n.pds <- length(c(pre.pd, mora.pd))

newClusters <- function(hits, dist.thresh = 0.05, sm.cluster.bound = 2) {
  res <- rep(-9999, n.pds)
  j <- 1
  for (i in c(pre.pd, mora.pd)) {
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
    res[j] <- length(new.clusters[new.clusters <= sm.cluster.bound])
    j <- j + 1
  }
  res
}

mys.res <- newClusters(mys.hits)
idn.res <- newClusters(idn.hits)

idn.mat <- as.data.frame(cbind(1:102, 1, idn.res, 0))
names(idn.mat) <- c("pd", "cid", "new.clusters", "mora")
idn.mat[idn.mat$pd > 67, "mora"] <- 1

png("../../write-up/images/idn.png")
plot(1:102, idn.res, type="l")
abline(v = 67, col = "red")
dev.off()

mys.mat <- as.data.frame(cbind(1:102, 0, mys.res, 0))
names(mys.mat) <- c("pd", "cid", "new.clusters", "mora")
mys.mat[mys.mat$pd > 67, "mora"] <- 1

png("../../write-up/images/mys.png")
plot(1:102, mys.res, type="l")
abline(v = 67, col = "red")
dev.off()

total.mat <- rbind(idn.mat, mys.mat)
model <- lm(new.clusters ~ 1 + pd*cid + pd*mora + mora*cid*pd, data=total.mat)
summary(model)

## sumtrend <- function(res) {
##   x1 <- 47:116
##   x2 <- 116:T
##   y1 <- res[x1]
##   y2 <- res[x2]
##   print(summary(lm(y1 ~ 1 + x1)))
##   print(summary(lm(y2 ~ 1 + x2)))
## }
## sumtrend(idn.res)
## sumtrend(mys.res)

