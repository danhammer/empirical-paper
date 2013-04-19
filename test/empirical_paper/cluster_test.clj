(ns empirics.edge-test
  (:use [midje sweet cascalog]
        clojure.contrib.graph
        cascalog.api
        empirics.cluster))

(def wide-net-sample
  "
  Edges associated with sample coordinates, when threshold is set
  to 4.5, such that all points are in a single cluster
  +---+---+---+---+---+
  |                 5 |
  +               4   +
  |                   |
  +                   +
  |         3         |
  +                   +
  |                   |
  +   2               +
  | 1                 |
  0---+---+---+---+---+
  "
  [[0 '(1 2)]
   [1 '(0 2)]
   [2 '(0 1 3)]
   [3 '(2 4)]
   [4 '(5 3)]
   [5 '(4)]])

(def moderate-net-sample
  "Edges associated with sample coordinates, when threshold is set to
  1.5, such that all points are in a single cluster"
  [[0 '(1)]
   [1 '(0 2)]
   [2 '(1)]
   [3 '(nil)]
   [4 '(5)]
   [5 '(4)]])

(facts
  (let [moderate-g (make-graph moderate-net-sample)
        wide-g (make-graph wide-net-sample)]

    ;; ensure that all nodes are represented within the constructed graph
    (-> moderate-g :nodes set) => #{:5 :4 :3 :2 :1 :0}
    (-> wide-g :nodes set)     => #{:5 :4 :3 :2 :1 :0}

    ;; find the strongly connected components
    (scc moderate-g) => [#{:1 :0 :2} #{:3} #{:4 :5}]
    (scc wide-g)     => [#{:0 :1 :2 :3 :4 :5}]

    ;; check that cluster-src properly tags each pixel ID with a
    ;; cluster ID (integer)
    (set (cluster-src moderate-g))
    => #{[0 :0]
         [0 :1]
         [0 :2]
         [1 :3]
         [2 :4]
         [2 :5]}

    (set (cluster-src wide-g))
    => #{[0 :0]
         [0 :1]
         [0 :2]
         [0 :3]
         [0 :4]
         [0 :5]}))
