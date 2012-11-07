library(foreign)
library(xtable)
library(ggplot2)
library(reshape)
library(texreg)

reg.data <- read.dta("../../write-up/data/processed/regression-data.dta")

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

price.data <- read.csv("~/Dropbox/defor-cluster/regdata.csv")
attach(price.data)
## wide <- reshape(price.data, idvar="pd", timevar="cntry", direction="wide")
k <- 1
measure <- new
iso <- "idn"



price.chg <- diff(palm_price, k)
pricechg.prop <- price.chg / palm_price[0:-k]
pricechg.prop <- pricechg.prop[0:(111-k)]

price.chg <- diff(palm_price, k)
price.prop <- price.chg / palm_price[0:-k]


detach(price.data)
