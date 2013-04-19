(ns empirics.margin
  (:use cascalog.api
        [forma.date-time :only (period->datetime)])
  (:require incanter.stats
            [cascalog.ops :as ops]))

(defn join-pds
  "Accepts a source of pixel coordinates with time period of detection
  and unique identifier.  Accepts another source with the unique
  identifier for each pixel and each cluster that it is a part of.
  Returns a source with the period of detection joined to the cluster
  identifier."
  [coord-src cluster-src]
  (<- [?cl ?id-key ?pd]
      (coord-src ?id-int ?pd _ _)
      (cluster-src ?cl ?id-key)
      ((ops/comp #'keyword #'str) ?id-int :> ?id-key)))

;; TODO: the following function may pose a minor problem, if two or
;; more clusters that started at different times ultimately merge.
;; Identifying the seed by the first hit will ignore this behavior. So
;; few clusters in Kalimantan actually do this, however, so that we
;; ignore this issue for now.

(defbufferop first-hit
  "Returns the earliest period within a certain cluster.  The seed of
  the cluster."
  [tuples]
  [[(reduce min (flatten tuples))]])

(defn cluster-start
  "Accepts the cluster and pixel sources (used for `join-pds`) and
  returns the cluster with the period that it was started."
  [pd-src]
  (<- [?cl ?init-pd]
      (pd-src ?cl ?idx ?pd)
      (first-hit ?pd :> ?init-pd)))

(defn indicator
  "A simple indicator function that returns 1 if x = y and 0
  otherwise"
  [x y]
  (if (== x y) 1 0))

(defn assign-seed
  "Accepts the cluster source and pixel source (used for `join-pds`)
  and returns a pixel-level source with the cluster, period, and
  indicator of whether the pixel was the seed of its designated
  cluster."
  [coord-src cluster-src]
  (let [pd-src (join-pds coord-src cluster-src)
        start-src (cluster-start pd-src)]
    (<- [?cl ?id-key ?pd ?seed-binary]
        (start-src ?cl ?init-pd)
        (pd-src ?cl ?id-key ?pd)
        (indicator ?pd ?init-pd :> ?seed-binary))))

(defn prop-new
  "Accepts the cluster source and pixel source (used for `join-pds`)
  and returns a source with the string reprentation of the FORMA
  period along with the proportion of new deforestation that is in a
  new cluster"
  [coord-src cluster-src]
  (<- [?str-pd ?prop]
      ((assign-seed coord-src cluster-src) _ _ ?pd ?seed-binary)
      (period->datetime "16" ?pd :> ?str-pd)
      (ops/avg ?seed-binary :> ?prop)))

(defn defor-rate
  "Accepts a coordinate source and returns a source with the number of
  new hits within each time period."
  [coord-src]
  (<- [?str-pd ?ct]
      (coord-src ?id ?pd _ _)
      (period->datetime "16" ?pd :> ?str-pd)
      (ops/count ?ct)))
