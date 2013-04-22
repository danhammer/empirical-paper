(ns empirics.workflow-test
  (:use [midje sweet cascalog]
        [environ.core :only (env)]
        cascalog.api
        empirics.workflow)
  (:require [clojure.java.io :as io]))

(defn- test-prob-src
  []
  (let [data-src [["500" 28 8 0 0 [0.01 0.01 0.02 0.50 0.60 0.70 0.80]]
                  ["500" 28 8 0 1 [0.01 0.01 0.02 0.02 0.60 0.70 0.80]]
                  ["500" 28 8 1 2 [0.01 0.01 0.02 0.02 0.02 0.02 0.02]]
                  ["500" 28 8 0 9 [0.01 0.01 0.02 0.50 0.60 0.70 0.80]]
                  ["500" 28 8 1 9 [0.01 0.01 0.02 0.50 0.60 0.70 0.80]]]]
    (?<- (hfs-seqfile "/tmp/all-prob-series" :sinkmode :replace)
         [?s-res ?modh ?modv ?s ?l ?prob-series]
         (data-src ?s-res ?modh ?modv ?s ?l ?prob-series))))

(defn- test-static-src
  []
  (let [data-src [["500" 28 8 0 0 "a" 23119 1080 "b" "c"]
                  ["500" 28 8 0 1 "a" 23119 1080 "b" "c"]
                  ["500" 28 8 1 2 "a" 23119 1080 "b" "c"]
                  ["500" 28 8 0 9 "a" 99999 1080 "b" "c"]
                  ["500" 28 8 1 9 "a" 99999 1080 "b" "c"]]]
    (?<- (hfs-seqfile "/tmp/all-static-seq/all" :sinkmode :replace)
         [?s-res ?modh ?modv ?s ?l ?vcf ?gadm ?ecoid ?hansen ?coast-dist]
         (data-src ?s-res ?modh ?modv ?s ?l ?vcf ?gadm ?ecoid ?hansen ?coast-dist))))

(def test-map
  {:raw-path      "/tmp/all-prob-series"
   :static-path   "/tmp/all-static-seq/all"
   :edge-path     "/tmp/edges"})


