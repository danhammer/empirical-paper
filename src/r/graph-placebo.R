## Graph placebo effect
library(ggplot2)

load("tester.RData")
load("warped-diff.RData")

## names(res) <- c("date", "iter.1", "iter.2")

png("../../write-up/images/placebo.png", width=900, height=500)
plot(x = res$date, y = res[["iter.1"]], pch = 16, cex = 0.5, col = "grey", ann = FALSE, bty = "n")
var.seq <- 2:ncol(res)
for (i in var.seq) {
  var <- paste("iter.", i, sep = "")
  points(x = res$date, y = res[[var]], pch = 16, cex = 0.5, col = "grey", ann = FALSE)
}
avg <- rowMeans(res[var.seq])
lines(x = res$date, y = avg, type = "l")
lines(x = res$date, y = warped.diff, type = "l", col = "red")
dev.off()
