
## read in the raw data with land characterstics, tagged to each pixel
## by its MODIS coordinates
slope.data <- read.csv("../../data/raw/clean-resamp.csv")

## remove first index column, which is extraneous
slope.data <- slope.data[,-1]


