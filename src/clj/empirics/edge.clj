(ns empirics.edge
  (:use cascalog.api)
  (:require incanter.stats
            [cascalog.ops :as ops]))

(defn add-constant
  "returns a tuple with a constant 1 prepended as an additional field"
  [x]
  [1 x])

(defn outer-join
  "Accepts a cascalog source of IDs only, and returns the outer
  join (or cartesian product) of the IDs as tap of separate tuples.
  Each ID is joined with every other ID through a join on a constant."
  [id-src]
  (let [const-src (<- [?c ?id]
                      (id-src ?id-init)
                      (add-constant ?id-init :> ?c ?id))]
    (<- [?id1 ?id2]
        (const-src ?c ?id1)
        (const-src ?c ?id2))))

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
  graph representation of an undirected graph."
  [coord-src thresh]
  (let [id-src (<- [?id] (coord-src ?id _ _ _ _))
        outer  (outer-join id-src)]
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
  (<- [!id ?id-vec]
      ((filter-dist coord-src thresh) !id !!id-link)
      (coord-src !id _ _ _ _)
      (get-edges !!id-link :> ?id-vec)
      (:distinct false)))

(defmain PixelEdges
  "Sink pixel edges to a sequence file."
  [coord-src-path output-src-path distance-threshold]
  (?- (hfs-seqfile output-src-path :sinkmode :replace)
      (create-edges coord-src-path distance-threshold)))
