(ns empirics.workflow
  (:use [cascalog.api]
        [cascalog.checkpoint :only (workflow)]
        [empirics.grabdata]
        [empirics.edge]
        [empirics.cluster]
        [empirics.margin])
  (:require [cascalog.ops :as ops]))

(def production-map
  "Bound to a map that contains the relevant S3 file paths to process
  the raw forma data into a form that can be analyzed locally."
  {:raw-path      "s3n://formatemp/output/all-probs-merged"
   :static-path   "s3n://pailbucket/all-static-seq/all"
   :hits-path     "s3n://formatemp/empirical-paper/hits"
   :dist-path     "s3n://formatemp/empirical-paper/dist"
   :edge-path     "s3n://formatemp/empirical-paper/edge"
   :cluster-path  "s3n://formatemp/empirical-paper/cluster"})

(defmain FirstStage
  "Accepts a global static pixel-characteristic and dynamic
  probability source from `seqfile-map`.  Returns the edges between
  deforested pixels in Borneo."
  [tmp-root & {:keys [probability-thresh
                      path-map]
               :or   {probability-thresh 50
                      path-map production-map}}]
  (?- (-> :hits-path path-map (hfs-seqfile :sinkmode :replace))
      (borneo-hits (-> :raw-path path-map hfs-seqfile)
                   (-> :static-path path-map hfs-seqfile)
                   probability-thresh)))

(defmain SecondStage
  "Accepts a global static pixel-characteristic and dynamic
  probability source from `seqfile-map`.  Returns the pairwise
  distances between pixels in borneo."
  [tmp-root & {:keys [distance-thresh path-map]
               :or   {distance-thresh 0.01 path-map production-map}}]
  (?- (-> :dist-path path-map (hfs-seqfile :sinkmode :replace))
      (filter-dist (-> :hits-path path-map hfs-seqfile) distance-thresh)))

(defmain ThirdStage
  "Compile the distance tuples into edges for use in a sub-graph
  finding algorithm"
  [tmp-root & {:keys [path-map] :or {path-map production-map}}]
  (?- (-> :edge-path path-map (hfs-seqfile :sinkmode :replace))
      (create-edges (-> :dist-path path-map hfs-seqfile))))

(defmain FourthStage
  "Create pixel identifier"
  [tmp-root & {:keys [path-map] :or {path-map production-map}}]
  (let [cl-src (-> :edge-path path-map hfs-seqfile make-graph cluster-src)]
    (?<- (-> :cluster-path path-map (hfs-seqfile :sinkmode :replace))
         [?cl-idx ?pixel-idx]
         (cl-src ?cl-idx ?pixel-idx))))

