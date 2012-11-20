library(reshape)
library(ggplot2)
source("clean-econ.R")
source("utils.R")

load("../../data/processed/cluster-count-01.Rdata")
sub.data <- full.data[get.year(full.data$date) >= 2008,]


policy.bars <- function(g) {
  ## Add shaded grey bars to the supplied ggplot time series,
  ## according to the dates of the three stages of the moratorium
  rect.df <- function(begin, end) {
    data.frame(xmin=as.Date(begin), xmax=as.Date(end), ymin=-Inf, ymax=Inf)
  }

  custom.bars <- function(x) {
    geom_rect(data=x, aes(xmin=xmin, xmax=xmax, ymin=ymin, ymax=ymax),
              alpha=0.20, inherit.aes = FALSE)
  }
  
  announce <- rect.df("2010-03-10", "2010-05-20")
  intent   <- rect.df("2010-10-20", "2011-01-01")
  enact    <- rect.df("2011-03-10", "2011-05-20")

  g <- g + custom.bars(announce)
  g <- g + custom.bars(intent)
  g <- g + custom.bars(enact)
  g
}

graph.land <- function(iso, land.type, bars = TRUE, out.name = FALSE) {
  ## Customized function to graph and save the characteristics of the
  ## incremental deforestation in new and old clusters
  if (out.name == FALSE) {
    name <- paste(iso, "-", land.type, ".png", sep="")
    f <- file.path("../../write-up/images", name)
  }
  new <- paste("new.", land.type, sep=""); old <- paste("old.", land.type, sep="")
  g.data <- sub.data[sub.data$cntry == iso, c("date", new, old)]
  g.data <- melt(g.data, id="date")
  names(g.data) <- c("date", "cluster.type", "land.char")
  g <- ggplot(data = g.data, aes(x = date, y = land.char, colour = cluster.type)) + geom_line()
  if (bars == TRUE) {
    g <- policy.bars(g)
  }
  g <- g + xlab("") + ylab("")
  ggsave(f, g)
  return(g)
}

## Graph total rates
png("../../write-up/images/total-rate.png", width=600, height=400)
g <- ggplot(data = sub.data, aes(x = date, y = total, colour = cntry)) + geom_line()
g <- policy.bars(g)
(g <- g + xlab("") + ylab(""))
dev.off()

## Graph smoothed proportion of deforestation in new clearing
png("../../write-up/images/smoothed-prop.png", width=600, height=400)
g <- ggplot(data = sub.data, aes(x = date, y = s.prop, colour = cntry)) + geom_line()
g <- policy.bars(g)
(g <- g + xlab("") + ylab(""))
dev.off()

## Graph slopes
graph.land("idn", "slope")
graph.land("mys", "slope")

## Graph water accumulation
graph.land("idn", "accum")
graph.land("mys", "accum")

## Graph elevation
graph.land("idn", "elev")
graph.land("mys", "elev")
