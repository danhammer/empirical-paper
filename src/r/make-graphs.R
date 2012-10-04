library(foreign)
library(xtable)
library(ggplot2)
library(reshape)
library(texreg)

reg.data <- read.dta("../../write-up/data/processed/regression-data.dta")
long.data <- read.dta("../../write-up/data/processed/long-clusters.dta")
date.data <- read.csv("../../write-up/data/raw/dates.csv", header = FALSE)

reg.data[["cntry"]] <- reg.data[["cntry"]] + 1
reg.data[reg.data[["cntry"]] == 2, 2] <-  0
reg.data[["pd"]] <- reg.data[["pd"]] / 23

table.out <- xtable(lm(prop ~ 1 + pd + cntry + post + pd*cntry*post, data=reg.data),
                    caption="Regression output",
                    label="fig:reg")
print.xtable(table.out, type="latex", file="../../write-up/tables/regout.tex")

# replaces xtable table from above
model1 <- lm(prop ~ 1 + cntry + post + cntry*post, data=reg.data)
model2 <- lm(prop ~ 1 + pd + cntry + post + cntry*post, data=reg.data)
model3 <- lm(prop ~ 1 + pd + cntry + post + pd*cntry*post, data=reg.data)
table.string <- texreg(list(model1, model2, model3),
                       model.names=c("(1)", "(2)", "(3)"),
                       digits=5,
                       table=FALSE,
                       use.packages=FALSE)
out <- capture.output(cat(table.string))
cat(out, file="../../write-up/tables/regout.tex", sep="\n")


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
