(ns empirics.workflow
  (:use [cascalog.api]
        [cascalog.checkpoint :only (workflow)])
  (:require [cascalog.ops :as ops]))

(def seqfile-map
  "Bound to a map that contains the relevant S3 file paths to process
  the raw forma data into a form that can be analyzed locally."
  {:raw-path      "s3n://pailbucket/all-prob-series"
   :static-path   "s3n://pailbucket/all-static-seq/all"
   :prob-path     "s3n://formatemp/empirical-paper/borneo-probs"
   :hits-path     "s3n://formatemp/empirical-paper/borneo-hits"})

(defn- to-seqfile [k]
  (hfs-seqfile (k seqfile-map)))

(defmain first-stage
  "Accepts a global static pixel-characteristic and dynamic
  probability source from `seqfile-map`.  Returns the edges between
  deforested pixels in Borneo."
  [tmp-root & {:keys [distance-thresh probability-thresh]
               :or   {distance-thresh 0.01 probability-thresh 0.5}}]
  (let [screen-src (apply screen-borneo
                          (map to-seqfile [:raw-path :static-path]))]

    (workflow [tmp-root]

              screen-step
              ([:tmp-dirs screen-path]
                 (?- (hfs-seqfile )
                     (borneo-hits screen-src 50)))

              



              stop-process
              ([]
                 "stop everything before deleting the temp directory"
                 (?- (hfs-seqfile "/mnt/hgfs/Dropbox/yikes")
                     (hfs-seqfile "/mnt/hgfs/Dropbox/yikestimes"))))))
