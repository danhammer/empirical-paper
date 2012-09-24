## Small example of clustering, given a certain cutoff height.

clusterExample <- function() {
  ## Define a set of points to cluster
  a <- rbind(c(1,2), c(4,6), c(0,0), c(0,8), c(1,4), c(0,7))
  plot(a, pch="", xlim=c(0,8),ylim=c(0,8))
  text(a, labels=c(1:6))

  ## Cluster the data by euclidean distance and a linkage defined by a
  ## single connection to any point already in the cluster.  Note that
  ## (1,4) is more than 3 units away from (0,0), but they are in the
  ## same cluster, since they are linked by (1,2)
  res <- hclust(dist(a, method="euclidean"), method="single")
  plot(res)

  ## Display a vector of cluster identifiers for each of the 6 points,
  ## with a threshold of a euclidean distance 3
  cutree(res, h=1.5)
}


plotHits <- function() {
  hits <- read.table("/home/dan/Downloads/borneo/part-00000")
  names(hits) <- c("lat", "lon", "pd")
  plot(hits$lon, hits$lat, pch=20, col="blue")
}

time.hcluster <- function(hit.latlon.mat) {
  ## The hit matrix is an Nx2 column of latitudes and longitudes
  ## Example usage: time.hcluster(cbind(hits$lon, hits$lat))
  t0 <- proc.time()
  res <- hclust(dist(hit.latlon.mat, method="euclidean"), method="single")
  proc.time() - t0
}

