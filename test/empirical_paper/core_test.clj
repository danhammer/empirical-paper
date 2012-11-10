(ns empirics.core-test
  (:use [midje sweet]
        cascalog.api
        empirics.core))

(def sample-prob-src
  "A sample source for testing.  There are 3 pixels with GADM
identifiers in the Borneo set.  Of these, there are 2 hits at the 50%
confidence threshold"
  [["500" 28 8 0 0 [0.01 0.01 0.02 0.50 0.60 0.70 0.80]]
   ["500" 28 8 0 1 [0.01 0.01 0.02 0.02 0.60 0.70 0.80]]
   ["500" 28 8 0 2 [0.01 0.01 0.02 0.02 0.02 0.02 0.02]]
   ["500" 28 8 0 3 [0.01 0.01 0.02 0.50 0.60 0.70 0.80]]
   ["500" 28 8 0 4 [0.01 0.01 0.02 0.50 0.60 0.70 0.80]]])

(def sample-static-src
  "The static characteristics for the sample, test source.  We don't
need the fields that are place-held with the a, b, and c string
characters."
  [["500" 28 8 0 0 "a" 23119 1080 "b" "c"]
   ["500" 28 8 0 1 "a" 23119 1080 "b" "c"]
   ["500" 28 8 0 2 "a" 23119 1080 "b" "c"]
   ["500" 28 8 0 3 "a" 99999 1080 "b" "c"]
   ["500" 28 8 0 4 "a" 99999 1080 "b" "c"]])

(fact "test that the proper number of pixels are within the screened
data set, based on the `sample-borneo` function"
  (count (first (??- (screen-borneo sample-prob-src sample-static-src)))) => 3)

(facts "test that (1) the number of hits are properly counted and (2)
the output observation is of the proper form."
  (let [screen-src (screen-borneo sample-prob-src sample-static-src)
        out-hits (first (??- (borneo-hits screen-src 50)))]
    (count out-hits) => 2
    (first out-hits) => [28 8 0 1 9.99375 101.542824 23119 6]))
