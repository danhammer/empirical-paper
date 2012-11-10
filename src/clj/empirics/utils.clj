(ns empirics.utils
  "supporting functions for cascalog queries in empirics.core"
  (:use [clojure.contrib.math :only (expt round)]))

(defn round-places
  "custom function to round a fload variable to a certain number of
  digits; used to shorten lat-lon coordinates."
  [decimals number]
  (let [factor (expt 10 decimals)]
    (double (/ (round (* factor number)) factor))))
