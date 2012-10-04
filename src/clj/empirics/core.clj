(ns empirics.core
  (:use [cascalog.api]
        [clojure.java.io :only (writer file)]
        [clojure.contrib.duck-streams :only (write-lines)]
        [empirics.utils :only (round-places)]
        [clojure.contrib.math :only (expt round)]
        [forma.hadoop.jobs.cdm :only (first-hit)]
        [forma.date-time :only (convert-period-res datetime->period period->datetime)])
  (:require [incanter.core :as i]
            [cascalog.ops :as ops]))

(defn to-dates [outpath]
  (let [f (file outpath)
        first-idx (datetime->period "16" "2005-12-31")
        last-idx  (datetime->period "16" "2012-06-25")
        date-range (range first-idx last-idx)
        rel-range (map #(- % first-idx) date-range)
        data (map vector rel-range
                  (map (partial period->datetime "16") date-range))]
    (with-open [w (writer outpath)]
      (.write w (apply str (interpose "\n" (map #(str (first %) "," (second %)) data)))))))

(defn count-pixels
  ;; Total pixels => 3096786
  [mys-path kali-path]
  (let [src (union (hfs-seqfile mys-path)
                   (hfs-seqfile kali-path))]
    (??<- [?ct]
          (src _ _ _ _ _ ?lat ?lon _ _ _)
          (ops/count ?ct))))


(defn borneo-hits
  "Example:
    (borneo-hits \"/home/dan/Downloads/mys-subsample\"
                             \"/home/dan/Downloads/kali-subsample\"
                             \"/home/dan/Downloads/borneo\"
                             50)

  There are 281,862 pixels subject to FORMA clearing between Jan 2006
  and June 2012, or 9.1 percent of forested pixels.  Ravaged.  This is
  a high upper bound; the entire pixel was probably not cleared."
  [mys-path kali-path out-path thresh]
  (let [src (union (hfs-seqfile mys-path)
                   (hfs-seqfile kali-path))
        [epoch first-pd] (map (partial datetime->period "16")
                              ["2000-01-01" "2005-12-31"])]
    (?<- (hfs-textline out-path :sinkmode :replace)
         [?rlat ?rlon ?gadm ?pd]
         (src _ _ _ _ _ ?lat ?lon ?gadm _ ?clean-series)
         (first-hit thresh ?clean-series :> ?pd)
         (round-places 5 ?lat :> ?rlat)
         (round-places 5 ?lon :> ?rlon))))

;; (defn borneo-hits
;;   [mys-path kali-path out-path thresh]
;;   (let [src (union (hfs-seqfile mys-path)
;;                    (hfs-seqfile kali-path))
;;         [epoch first-pd] (map (partial datetime->period "16")
;;                               ["2000-01-01" "2005-12-31"])]
;;     (?<- (hfs-seqfile out-path :sinkmode :replace)
;;          [?sm-lat ?sm-lon ?period]
;;          (src _ _ _ _ _ ?lat ?lon _ _ ?clean-series)
;;          (first-hit thresh ?clean-series :> ?first-hit-idx)
;;          (+ first-pd ?first-hit-idx :> ?period)
;;          (round-places ?lat 5 :> ?sm-lat)
;;          (round-places ?lon 5 :> ?sm-lon))))

;; (defn to-subtap [name]
;;   (let [src (hfs-seqfile (str "/home/dan/Downloads/" name))]
;;     (<- [?lat ?lon ?clean-series]
;;         (src _ _ _ _ _ ?lat ?lon _ _ ?clean-series)
;;         (:distinct true))))

;; (defn to-borneo []
;;   (let [mys (hfs-seqfile "/home/dan/Downloads/mys-subsample")
;;         idn (hfs-seqfile "/home/dan/Downloads/kali-subsample")
;;         both (union mys idn)]
;;     (?<- (hfs-seqfile "/home/dan/Downloads/borneo" :sinkmode :replace)
;;          [?lat ?lon ?clean-series]
         ;; (both  _ _ _ _ _ ?lat ?lon _ _ ?clean-series))))

;; (first-hit thresh ?clean-series :> ?first-hit-idx)
;; (+ start-period ?first-hit-idx :> ?period)
;; (date/convert-period-res tres tres-out ?period :> ?period-new-res)
;; (- ?period-new-res epoch :> ?rp)
;; (min-period ?rp :> ?p)

;; (let [src (hfs-seqfile "/home/dan/Downloads/borneo")]
;;   (?<- (stdout)
;;        [?lat ?lon ?clean-series]
;;        (src ?lat ?lon ?clean-series)))

;; The query to screen out all pixels that are not on the island of
;; Borneo; run on the cluster, 30 minutes on 5 high-memory instances
;; starting from the Brazil/Indonesia data set


;; (use 'forma.hadoop.jobs.scatter)
;; (in-ns 'forma.hadoop.jobs.scatter)
;; (use 'forma.postprocess.output)

;; (def gadm-set
;;   #{23051 23052 23053 23054 23055 23056 23057 23058 23059 23060 23042 23043
;;     23044 23045 23046 23047 23048 23049 23050 23061 23062 23063 23064 23065
;;     23066 23067 23068 23069 23070 23071 23072 23073 23074 23075 23076 23077
;;     23078 23079 23080 23081 23082 23083 23084 23085 23086 23087 23088 23089
;;     23090 23091 23092 23093 23094 23095 23096 23097 23098 23099 23100 23101
;;     23102 23103 23104 23105 23106 23107 23108 23109 23110 23111 23112 23113
;;     23114 23115 23116 23117 23118 23119 23120 15488 15489 15490 15491 15492
;;     15493 15494 15495 15496 15497 15498 15499 15500 15501 15502 15503 15504
;;     15505 15506 15507 15508 15509 15510 15511 15512 15513 15514 15515 15516
;;     15517 15518 15519 15520 15521 15522 15523 15524 15525 15526 15527 15528
;;     15529 15530 15531 15532 15533 15534 15535 15536 15537})


;; (let [forma-src (hfs-seqfile "s3n://formareset/2012-07-03")
;;       static-src (hfs-seqfile "s3n://pailbucket/all-static-seq/all")]
;;   (?<- (hfs-seqfile "s3n://formatemp/empirical-paper/mys" :sinkmode :replace)
;;        [?sres ?modh ?modv ?s ?l ?lat ?lon ?gadm ?ecoid ?clean-series]
;;        (forma-src ?sres ?modh ?modv ?s ?l ?prob-series)
;;        (r/modis->latlon ?sres ?modh ?modv ?s ?l :> ?lat ?lon)
;;        (static-src ?sres ?modh ?modv ?s ?l _ ?gadm ?ecoid _ _)
;;        (contains? gadm-set ?gadm)
;;        (clean-probs ?prob-series :> ?clean-series)))


