library('sp')

## load a file from GADM (you just have to specify the countries "special part" of the file name, like "ARG" for Argentina. Optionally you can specify which level you want to have
loadGADM <- function (fileName, level = 0, ...) {
    load(url(paste("http://gadm.org/data/rda/", fileName, "_adm", level, ".RData", sep     = "")))
    gadm
}

## the maps objects get a prefix (like "ARG_" for Argentina)
changeGADMPrefix <- function (GADM, prefix) {
    GADM <- spChFIDs(GADM, paste(prefix, row.names(GADM), sep = "_"))
    GADM
}

## load file and change prefix
loadChangePrefix <- function (fileName, level = 0, ...) {
    theFile <- loadGADM(fileName, level)
    theFile <- changeGADMPrefix(theFile, fileName)
    theFile
}

## this function creates a SpatialPolygonsDataFrame that contains all maps you specify in "fileNames".
## E.g.: 
## spdf <- getCountries(c("ARG","BOL","CHL"))
## plot(spdf) # should draw a map with Brasil, Argentina and Chile on it.
getCountries <- function (fileNames, level = 0, ...) {
    polygon <- sapply(fileNames, loadChangePrefix, level)
    polyMap <- do.call("rbind", polygon)
    polyMap
}

graphBorneo <- function(outname) {
  spdf <- getCountries(c("MYS", "IDN"), level=2)
  kali.prov <- c(1266, 1268, 1267, 1989, 1269, 1988)
  kali <- spdf[spdf$ID_1 %in% kali.prov,]
  png(paste("../images/", outname, ".png", sep=""), width=580, height=200, res=80)
  plot(kali)
  axis(1)
  axis(2)
  dev.off()
}

mys.gadm <- c("23051", "23052", "23053", "23054", "23055", "23056",
              "23057", "23058", "23059", "23060", "23042", "23043",
              "23044", "23045", "23046", "23047", "23048", "23049",
              "23050", "23061", "23062", "23063", "23064", "23065",
              "23066", "23067", "23068", "23069", "23070", "23071",
              "23072", "23073", "23074", "23075", "23076", "23077",
              "23078", "23079", "23080", "23081", "23082", "23083",
              "23084", "23085", "23086", "23087", "23088", "23089",
              "23090", "23091", "23092", "23093", "23094", "23095",
              "23096", "23097", "23098", "23099", "23100", "23101",
              "23102", "23103", "23104", "23105", "23106", "23107",
              "23108", "23109", "23110", "23111", "23112", "23113",
              "23114", "23115", "23116", "23117", "23118", "23119",
              "23120")

idn.gadm <- c("15488", "15489", "15490", "15491", "15492", "15493",
              "15494", "15495", "15496", "15497", "15498", "15499",
              "15500", "15501", "15502", "15503", "15504", "15505",
              "15506", "15507", "15508", "15509", "15510", "15511",
              "15512", "15513", "15514", "15515", "15516", "15517",
              "15518", "15519", "15520", "15521", "15522", "15523",
              "15524", "15525", "15526", "15527", "15528", "15529",
              "15530", "15531", "15532", "15533", "15534", "15535",
              "15536", "15537")
