(ns empirics.cluster
  (:use cascalog.api
        empirics.edge
        clojure.contrib.graph))

(defn tuple->edge
  "Accepts a tuple with the uniqe ID of a node (an integer) and a list
  of unique IDs, identifying connections to the supplied node.
  Returns a map representation of the edge, ready for input into a
  graph function."
  [[node edge-vec]]
  (let [int->key (fn [i] (-> i str keyword))]
    (if (nil? (first edge-vec))
      {(int->key node) #{}}
      {(int->key node) (set (map int->key edge-vec))})))

(defn make-graph
  "Accepts a cascalog source of coordinates along with a distance
  threshold to define the edge definition.  Returns a directed graph
  structure."
  [coord-src thresh]
  (let [
        ;; evaluate the cascalog query to create edge tuples
        [edge-tuples] (??- (create-edges coord-src thresh))

        ;; translate the edge tuples into a single map, properly
        ;; formatted for the graph struct
        edge-map (apply merge
                        (map tuple->edge edge-tuples))]
    
    ;; convert the collection of edges to a graph struct
    (struct directed-graph (keys edge-map) edge-map)))

(defn cl-tupelize
  "Prepend the unique cluster ID for all nodes tagged within the
  cluster"
  [[cl-idx node-set]]
  (for [x node-set] [cl-idx x]))

(defn cluster-src
  "Accepts a graph and returns a source of tuples, where the cluster
  index is the first field (integer) and the second is the unique
  keyword identifier of the node within the identified cluster"
  [graph]
  (apply concat
         (map cl-tupelize
              (map-indexed vector (scc graph)))))


