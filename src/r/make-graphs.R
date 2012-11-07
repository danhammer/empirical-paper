library(foreign)
library(xtable)
library(ggplot2)
library(reshape)
library(texreg)

reg.data <- read.dta("../../write-up/data/processed/regression-data.dta")
long.data <- read.dta("../../write-up/data/processed/long-clusters.dta")
date.data <- read.csv("../../write-up/data/raw/dates.csv", header = FALSE)

reg.data <- read.dta("../../write-up/data/processed/regression-data.dta")
reg.data[["cntry"]] <- reg.data[["cntry"]] + 1
reg.data[reg.data[["cntry"]] == 2, 2] <-  0

ts.data <- merge(reg.data, date.data, by.x = "pd", by.y = "V1")[,c("prop", "V2", "cntry")]
names(ts.data) <- c("proportion", "date", "country")
ts.data[["date"]] <- as.Date(ts.data[["date"]], "%Y-%m-%d")

idn.idx <- ts.data[["country"]] == 1
mys.idx <- ts.data[["country"]] == 0
ts.data[["country"]][idn.idx] <- "IDN"
ts.data[["country"]][mys.idx] <- "MYS"

png(filename = "../../write-up/images/prop.png", width = 420, height = 280, units = 'px')
prop.g <- ggplot(data=ts.data, aes(x=date,y=proportion,colour=country)) + geom_line()

rect.one <- data.frame(xmin=as.Date("2010-03-10"), xmax=as.Date("2010-05-20"), ymin=-Inf, ymax=Inf)
rect.two <- data.frame(xmin=as.Date("2010-10-20"), xmax=as.Date("2011-01-01"), ymin=-Inf, ymax=Inf)
rect.tre <- data.frame(xmin=as.Date("2011-03-10"), xmax=as.Date("2011-05-20"), ymin=-Inf, ymax=Inf)

prop.g <- prop.g + geom_rect(data=rect.one, aes(xmin=xmin, xmax=xmax, ymin=ymin, ymax=ymax),
                                       alpha=0.20, inherit.aes = FALSE)
prop.g <- prop.g + geom_rect(data=rect.two, aes(xmin=xmin, xmax=xmax, ymin=ymin, ymax=ymax),
                                       alpha=0.20, inherit.aes = FALSE)
prop.g <- prop.g + geom_rect(data=rect.tre, aes(xmin=xmin, xmax=xmax, ymin=ymin, ymax=ymax),
                                       alpha=0.20, inherit.aes = FALSE)
prop.g <- prop.g + opts(axis.title.x = theme_blank(),
                        axis.title.y = theme_blank(),
                        legend.position = "none")
prop.g
dev.off()

alert.data <- merge(long.data, date.data, by.x = "pd", by.y = "V1")
alert.data <- alert.data[alert.data[["pd"]] >= 46,c("idn_alert", "mys_alert","V2")]
names(alert.data) <- c("idn", "mys", "date")
alert.data[["date"]] <- as.Date(alert.data[["date"]], "%Y-%m-%d")
alert.data[["id"]] <- 46:146 
alert.data <- melt(alert.data, id=c("id", "date"))

png(filename = "../../write-up/images/alert.png", width = 420, height = 280, units = 'px')
alert.g <- ggplot(data=alert.data, aes(x=date,y=value,colour=variable)) + geom_line()

rect.one <- data.frame(xmin=as.Date("2010-03-10"), xmax=as.Date("2010-05-20"), ymin=-Inf, ymax=Inf)
rect.two <- data.frame(xmin=as.Date("2010-10-20"), xmax=as.Date("2011-01-01"), ymin=-Inf, ymax=Inf)
rect.tre <- data.frame(xmin=as.Date("2011-03-10"), xmax=as.Date("2011-05-20"), ymin=-Inf, ymax=Inf)

alert.g <- alert.g + geom_rect(data=rect.one, aes(xmin=xmin, xmax=xmax, ymin=ymin, ymax=ymax),
                                       alpha=0.20, inherit.aes = FALSE)
alert.g <- alert.g + geom_rect(data=rect.two, aes(xmin=xmin, xmax=xmax, ymin=ymin, ymax=ymax),
                                       alpha=0.20, inherit.aes = FALSE)
alert.g <- alert.g + geom_rect(data=rect.tre, aes(xmin=xmin, xmax=xmax, ymin=ymin, ymax=ymax),
                                       alpha=0.20, inherit.aes = FALSE)
alert.g <- alert.g + opts(axis.title.x = theme_blank(),
                        axis.title.y = theme_blank(),
                        legend.position = "none")
alert.g
dev.off()

alert.data <- merge(long.data, date.data, by.x = "pd", by.y = "V1")
alert.data <- alert.data[alert.data[["pd"]] >= 46,]
names(alert.data)[8] <- "date"
alert.data[["date"]] <- as.Date(alert.data[["date"]], "%Y-%m-%d")

png(filename = "../../write-up/images/mys-iso.png", width = 420, height = 280, units = 'px')
alert.g <- ggplot(data=alert.data, aes(x=prop_mys,y=mys_alert,colour=date))
alert.g <- alert.g + geom_point(size=3) + labs(colour = "Year")
alert.g <- alert.g + scale_y_continuous('Total hits') + scale_x_continuous('New proportion')
alert.g
dev.off()

png(filename = "../../write-up/images/idn-iso.png", width = 420, height = 280, units = 'px')
alert.g <- ggplot(data=alert.data, aes(x=prop_idn,y=idn_alert,colour=date))
alert.g <- alert.g + geom_point(size=3) + labs(colour = "Year")
alert.g <- alert.g + scale_y_continuous('Total hits') + scale_x_continuous('New proportion')
alert.g
dev.off()


png(filename = "../../write-up/images/slope-idn.png", width = 600, height = 300, units = 'px')
data <- read.csv("~/Dropbox/defor-cluster/regdata.csv")
slope.data <- merge(data, date.data, by.x = "pd", by.y = "V1")
slope.data[["V2"]] <- as.Date(slope.data[["V2"]], "%Y-%m-%d")
sub.data <- slope.data[slope.data$cntry == "idn", c("V2", "slope_old", "slope_new")]
names(sub.data) <- c("date", "existing", "new")
m <- melt(sub.data, id=c("date"))
names(m) <- c("date", "cluster.type", "slope")
m <- m[m$date > as.Date("2008-01-01"), ]
g <- ggplot(data=m, aes(x=date,y=slope,colour=cluster.type)) + geom_line()

rect.one <- data.frame(xmin=as.Date("2010-03-10"), xmax=as.Date("2010-05-20"), ymin=-Inf, ymax=Inf)
rect.two <- data.frame(xmin=as.Date("2010-10-20"), xmax=as.Date("2011-01-01"), ymin=-Inf, ymax=Inf)
rect.tre <- data.frame(xmin=as.Date("2011-03-10"), xmax=as.Date("2011-05-20"), ymin=-Inf, ymax=Inf)

g <- g + geom_rect(data=rect.one, aes(xmin=xmin, xmax=xmax, ymin=ymin, ymax=ymax),
                                       alpha=0.20, inherit.aes = FALSE)
g <- g + geom_rect(data=rect.two, aes(xmin=xmin, xmax=xmax, ymin=ymin, ymax=ymax),
                                       alpha=0.20, inherit.aes = FALSE)
g <- g + geom_rect(data=rect.tre, aes(xmin=xmin, xmax=xmax, ymin=ymin, ymax=ymax),
                                       alpha=0.20, inherit.aes = FALSE)
g
dev.off()
