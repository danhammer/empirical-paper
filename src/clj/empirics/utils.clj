(ns empirics.utils
  (:use [clojure.contrib.math :only (expt round)]))

(defn round-places [decimals number]
  (let [factor (expt 10 decimals)]
    (double (/ (round (* factor number)) factor))))
