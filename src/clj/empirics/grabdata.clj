(ns empirics.grabdata
  "A set of functions to screen and preprocess data for analysis in
the empirical paper.  The raw FORMA data are stored in two sequence
files on S3, one for the probability data and one for the static data.
These locations, along with the output path, are stored in
`seqfile-map` for convenience.  Once the screening has been run on a
cluster (which takes approximately 20 minutes on 5 high-memory
instances) the output data can be further processed locally"
  (:use [cascalog.api]
        [empirics.utils :only (round-places)]
        [forma.hadoop.jobs.cdm :only (first-hit)]
        [forma.hoptree :only (global-index TileRowCol*)]
        [forma.reproject :only (modis->latlon)]
        [forma.postprocess.output :only (clean-probs)])
  (:require [cascalog.ops :as ops]))

(def gadm-set
  "Returns a set of GADM second-level administrative codes for all
  subprovinces in Borneo (both for Malaysia and Indonesia)"
  #{23051 23052 23053 23054 23055 23056 23057 23058 23059 23060 23042 23043
    23044 23045 23046 23047 23048 23049 23050 23061 23062 23063 23064 23065
    23066 23067 23068 23069 23070 23071 23072 23073 23074 23075 23076 23077
    23078 23079 23080 23081 23082 23083 23084 23085 23086 23087 23088 23089
    23090 23091 23092 23093 23094 23095 23096 23097 23098 23099 23100 23101
    23102 23103 23104 23105 23106 23107 23108 23109 23110 23111 23112 23113
    23114 23115 23116 23117 23118 23119 23120 15488 15489 15490 15491 15492
    15493 15494 15495 15496 15497 15498 15499 15500 15501 15502 15503 15504
    15505 15506 15507 15508 15509 15510 15511 15512 15513 15514 15515 15516
    15517 15518 15519 15520 15521 15522 15523 15524 15525 15526 15527 15528
    15529 15530 15531 15532 15533 15534 15535 15536 15537})

(defn screen-borneo
  "Accepts a source of the raw probability series for each pixel, and
  returns the cleaned series for all pixels within Borneo."
  [prob-src static-src]
  (<- [?modh ?modv ?sample ?line ?lat ?lon ?gadm ?ecoid ?clean-series]
      (prob-src ?sres ?modh ?modv ?sample ?line ?prob-series)
      (modis->latlon ?sres ?modh ?modv ?sample ?line :> ?lat ?lon)
      (static-src ?sres ?modh ?modv ?sample ?line ?vcf ?gadm ?ecoid ?hansen ?coast-dist)
      (contains? gadm-set ?gadm)
      (first ?prob-series :> ?first-elem)
      (symbol? ?first-elem :> false)
      (clean-probs ?prob-series -9999.0 :> ?clean-series)
      (:distinct false)))

(defn borneo-hits
  "Accepts a source of screened pixels and their cleaned probability
  series and returns a tap with pixel identifiers and the first period
  at which the probability of the pixel exceeded the supplied
  threshold.  Note that it /only/ returns pixels that eventually
  exceed the threshold -- the pixels that are considered hits."
  [prob-src static-src prob-threshold]
  (let [screen-src (screen-borneo prob-src static-src)]
    (<- [?id ?rlat ?rlon ?gadm ?pd]
        (screen-src ?modh ?modv ?sample ?line ?lat ?lon ?gadm ?ecoid ?clean-series)
        (first-hit prob-threshold ?clean-series :> ?pd)
        (round-places 6 ?lat :> ?rlat)
        (round-places 6 ?lon :> ?rlon)
        (TileRowCol* ?modh ?modv ?sample ?line :> ?trc)
        (global-index "500" ?trc :> ?id)
        (:distinct false))))
