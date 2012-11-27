## Create an economics data set that is snapped to the exact dates of
## the FORMA observations

## Load an example FORMA data set to get the exact FORMA dates
load("../../data/processed/cluster-count-01.Rdata")

## Load the daily economics data as econ.data data frame
source("clean-econ.R")

snap.econ <- econ.data[econ.data$date %in% unique(full.data$date), ]
snap.econ <- snap.econ[order(snap.econ$date), ]
save(snap.econ, file="../../data/processed/snap-econ.Rdata")
