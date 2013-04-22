(ns empirics.workflow
  (:use [cascalog.api]
        [cascalog.checkpoint :only (workflow)]
        [empirics.grabdata]
        [empirics.edge])
  (:require [cascalog.ops :as ops]))

(def production-map
  "Bound to a map that contains the relevant S3 file paths to process
  the raw forma data into a form that can be analyzed locally."
  {:raw-path      "s3n://pailbucket/all-prob-series"
   :static-path   "s3n://pailbucket/all-static-seq/all"
   :edge-path     "s3n://formatemp/empirical-paper/edges"})

(defmain first-stage
  "Accepts a global static pixel-characteristic and dynamic
  probability source from `seqfile-map`.  Returns the edges between
  deforested pixels in Borneo."
  [tmp-root & {:keys [distance-thresh
                      probability-thresh
                      path-map]
               :or   {distance-thresh 0.01
                      probability-thresh 50
                      path-map production-map}}]

  (workflow [tmp-root]

            screen-step
            ([:tmp-dirs screen-path]
               (?- (hfs-seqfile screen-path :sinkmode :replace)
                   (borneo-hits (-> :raw-path path-map hfs-seqfile)
                                (-> :static-path path-map hfs-seqfile)
                                probability-thresh)))
            edge-step
            ([]
               (?- (-> :edge-path path-map (hfs-seqfile :sinkmode :replace))
                   (create-edges (hfs-seqfile screen-path) distance-thresh)))))
