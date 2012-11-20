library(reshape)
library(ggplot2)
source("clean-econ.R")
source("utils.R")

load("../../data/processed/cluster-count-01.Rdata")
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
  g <- g + xlab("") + ylab("")
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
