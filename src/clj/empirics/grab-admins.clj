(ns empirics.grab-admins
  "generate a textline for merging GADM codes at the pixel level"
  (:use [cascalog.api]
        [empirics.core :only (seqfile-map)])
  (:require [cascalog.ops :as ops]))

(def text-path
  {:raw-hits "/mnt/hgfs/Dropbox/github/danhammer/empirical-paper/data/raw/borneo-hits/full-hits.txt"
   :out-path "/mnt/hgfs/Dropbox/github/danhammer/empirical-paper/data/processed/admin-map"})


(defn data-peek []
  (let [src (hfs-textline (:raw-hits text-path))]
    (?<- (hfs-textline (:out-path text-path))
         [?mod-h ?mod-v ?s ?l ?gadm]
         (src ?line)
         (clojure.string/split ?line #"\s+" :> ?mod-h ?mod-v ?s ?l _ _ ?gadm _))))



