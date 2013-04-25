(ns empirics.edge
  (:use cascalog.api)
  (:require incanter.stats
            [cascalog.ops :as ops]))

(defn gadm->cntry [gadm]
  (let [first-digit (-> gadm str first str)]
    (if (= first-digit "1") "idn" "mys")))

(defn coord-distance
  "Returns the euclidean distance of the supplied coordinates,
  specifically within a 2D plane."
  [x1 y1 x2 y2]
  (incanter.stats/euclidean-distance [x1 y1] [x2 y2]))

(defn filter-dist
  "Accepts a source of unique IDs and lat-lon coordinates of the
  points.  Returns the start and end nodes of each edge that is less
  than the length of the supplied distance threshold `thresh`.  Note
  that each edge is duplicated, since an edge between A -- B is
  identical to the edge B -- A.  The result is effectively a directed
  graph representation of an undirected graph. Only compares pixels
  within the same country"
  [coord-src thresh]
  (let [cntry-src (<- [?id ?cntry]
                      (coord-src ?id _ _ _ ?gadm)
                      (gadm->cntry ?gadm :> ?cntry))
        outer (<- [?id1 ?id2]
                  (cntry-src ?id1 ?cntry)
                  (cntry-src ?id2 ?cntry))]
    (<- [?id1 ?id2]
        (outer ?id1 ?id2)
        (coord-src ?id1 ?x1 ?y1 _ _)
        (coord-src ?id2 ?x2 ?y2 _ _)
        (coord-distance ?x1 ?y1 ?x2 ?y2 :> ?d)
        (< ?d thresh)
        (> ?d 0))))

(defbufferop get-edges
  "Returns a vector of connected nodes, flattened and in vector form."
  [tuples]
  [[(flatten tuples)]])

(defn create-edges
  "Accepts a source of coordinates of the form:

    [[unique-id lat lon pd gadm] ... ]

  and returns a clojure data structure of the edges, with the unique
  ID converted to keywords."
  [coord-src thresh]
  (<- [?id ?id-vec]
      ((filter-dist coord-src thresh) ?id ?id-link)
      (coord-src ?id _ _ _ _)
      (get-edges ?id-link :> ?id-vec)
      (:distinct false)))
