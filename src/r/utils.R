library(texreg)

get.year <- function(date) {
  ## Accepts an R date object and returns the year with a numeric data
  ## type
  as.numeric(format(date, "%Y"))
}

expand.date <- function(x) {
  ## Accepts a string of the form 05/2009 and returns a date object,
  ## expanding the time series to 16-day resolution; used for exchange
  ## rate cleaning
  dates <- c(paste("01/", x, sep=""), paste("15/", x, sep=""))
  as.Date(dates, "%d/%m/%Y")
}

annual.intervals <- function(year) {
  ## Creates a full set of FORMA dates for a year: starting with Jan
  ## 01, and incrementing 16 days until the end of the year
  init.str <- paste(year, "-01-01", sep="")
  seq(as.Date(init.str), length.out = 23, by="16 days")
}

forma.date <- function(forma.pd) {
  ## Convert forma index to the date period; can accept a sequence of
  ## indices.
  max.year <- max(ceiling(forma.pd/23) + 2005)
  full <- do.call(c, lapply(2005:max.year, annual.intervals))
  full[forma.pd + 23]
}

daily.interpolation <- function(df, var.name) {
  ## Spline interpolation of a variable var.name in a data frame that
  ## includes a variable date to daily variable.
  x <- data.frame(date=seq(min(df$date), max(df$date), by="1 day"))
  expanded <- merge(x, df, by=c("date"), all.x = TRUE)
  for (var in var.name) {
    expanded[[var]] <- na.spline(expanded[[var]])
  }
  expanded
}

create.table <- function(model.list, file.name, colnames=c("(1)", "(2)", "(3)")) {
  ## Create a tex fragment of a standardized table, saving to the
  ## supplied file name in the tables directory
  if (length(colnames) == 3) {
    var.names=c("(Intercept)", "country", "post", "price", "price^2", "country:post")
  }
  else {
    var.names=c("(Intercept)", "country", "post", "price", "price^2", "country:post", "exchange.rate")
  }
  path <- file.path("../../write-up/tables", file.name)
  table.string <- texreg(model.list, digits=3, model.names=colnames, custom.names=var.names,
                         table=FALSE, use.packages=FALSE)
  out <- capture.output(cat(table.string))
  cat(out, file = path, sep="\n")
}

