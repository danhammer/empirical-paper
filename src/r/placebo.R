library(texreg)
library(TTR)
source("utils.R")
load("../../data/processed/snap-econ.Rdata")

gadm.data <- read.table("../../data/processed/admin-map/part-00000")
names(gadm.data) <- c("h", "v", "s", "l", "gadm")

mys.gadm <- c(23051, 23052, 23053, 23054, 23055, 23056, 23057, 23058,
              23059, 23060, 23042, 23043, 23044, 23045, 23046, 23047,
              23048, 23049, 23050, 23061, 23062, 23063, 23064, 23065,
              23066, 23067, 23068, 23069, 23070, 23071, 23072, 23073,
              23074, 23075, 23076, 23077, 23078, 23079, 23080, 23081,
              23082, 23083, 23084, 23085, 23086, 23087, 23088, 23089,
              23090, 23091, 23092, 23093, 23094, 23095, 23096, 23097,
              23098, 23099, 23100, 23101, 23102, 23103, 23104, 23105,
              23106, 23107, 23108, 23109, 23110, 23111, 23112, 23113,
              23114, 23115, 23116, 23117, 23118, 23119, 23120)

idn.gadm <- c(15488, 15489, 15490, 15491, 15492, 15493, 15494, 15495,
              15496, 15497, 15498, 15499, 15500, 15501, 15502, 15503,
              15504, 15505, 15506, 15507, 15508, 15509, 15510, 15511,
              15512, 15513, 15514, 15515, 15516, 15517, 15518, 15519,
              15520, 15521, 15522, 15523, 15524, 15525, 15526, 15527,
              15528, 15529, 15530, 15531, 15532, 15533, 15534, 15535,
              15536, 15537)

findGadm <- function(iso) {
  data <- read.cluster(155, iso)
  interval.data <- merge(data, gadm.data, by = c("h", "v", "s", "l"))

  x <- aggregate(interval.data$gadm, list(interval.data$cl_155), max)[, c("Group.1", "x")]
  names(x) <- c("cl_155", "gadm")

  gadm.match <- merge(data, x, by = c("cl_155"))[ , c("h", "v", "s", "l", "gadm")]
  return(gadm.match)
}

calculateProp <- function(df, grp.num) {
  grp.data <- df[df$grp == grp.num, ]
  prop <- sum(grp.data["new.cluster"]) / sum(grp.data["new.bin"])
  return(prop)
}

gadm.match <- findGadm("idn")

iteration.idn <- function() {
  idn.training <- sample(idn.gadm, floor(length(idn.gadm)/2))

  .calcDiff <- function(interval.num) {
     x <- new.cluster(new.hits(interval.num, "idn"))
     x <- merge(x, gadm.match, by = c("h", "v", "s", "l"))
     
     x$grp <- ifelse(x$gadm %in% idn.training, 1, 0)
     diff <- calculateProp(x, 0) - calculateProp(x, 1)
     return(diff)
  }

  res <- sapply(47:155, .calcDiff)

  return(res)
}

res.placebo <- data.frame(date = forma.date(47:155))

.main <- function(B) {
  for (i in seq(B)) {
    var.name <- paste("iter.", i, sep = "")
    print(var.name)
    res.placebo[[var.name]] <- iteration.idn()
  }
  return(res.placebo)
}

res <- .main(100)

save(res, file = "tester.RData")
