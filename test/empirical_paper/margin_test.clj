(ns empirics.margin-test
  (:use [midje sweet cascalog]
        cascalog.api
        empirics.margin)
    (:require incanter.stats))

(def sample-coords
  
  ;; Sample coordinates, displayed
  ;; +---+---+---+---+---+
  ;; |                 5 |
  ;; +               4   +
  ;; |                   |
  ;; +                   +
  ;; |         3         |
  ;; +                   +
  ;; |                   |
  ;; +   2               +
  ;; | 1                 |
  ;; 0---+---+---+---+---+
  
  [[0 814 0 0]
   [1 812 1 1]
   [2 813 2 2]
   [3 811 5 5]
   [4 814 8 8]
   [5 813 9 9]])

(def sample-cluster-src
  [[0 :0]
   [0 :1]
   [0 :2]
   [1 :3]
   [2 :4]
   [2 :5]])

(facts
  "check final timeseries output"
  
  (prop-new sample-coords sample-cluster-src)
  
  => (produces [["2005-04-07" 1.0]
                ["2005-04-23" 1.0]
                ["2005-05-09" 0.5]
                ["2005-05-25" 0.0]])

  (defor-rate sample-coords)

  => (produces [["2005-04-07" 1]
                ["2005-04-23" 1]
                ["2005-05-09" 2]
                ["2005-05-25" 2]]))
