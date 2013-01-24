(ns empirics.sim
  (:use [cascalog.api]
        [empirics.utils :only (round-places)])
  (:require [cascalog.ops :as ops]
            [incanter.core :as i]
            [incanter.charts :as c]))

(defn increasing-returns
  [T e]
  (let [m (i/pow T e)]
    (map (comp
          (partial + m)
          (partial * -1)
          #(i/pow % e))
         (range T))))

(defn sandwich [v coll]
  (flatten (conj coll coll v coll)))

(defn marginal-cost
  [T & {:keys [b e] :or {b (int (/ T 2)) e 1/3}}]
  (let [base (increasing-returns T e)
        mx   (/ (reduce max base) 2)]
    (map +
         base
         (take T (sandwich mx (repeat b 0))))))

(defn view-cost
  [T cost-fn]
  (c/xy-plot (range T) (cost-fn T)))

(defn view-costs [T]
  (let [plot (view-cost T marginal-cost)]
    (doto plot
      (c/add-lines (range T)
                   (map (partial + 1.5) (marginal-cost T :e 1/4 :b 1000))))))


(defn growth-fn [r K g]
  (* (* r g) (- 1 (/ g K))))

(defn growth-graph [r K m]
  (map (partial growth-fn r K) (range 0 m)))

(defn view-growth [r K m alpha]
  (let [plot (c/xy-plot (range m) (growth-graph r K m))]
    (i/view
     (doto plot
       (c/add-lines (range m) (map (partial * alpha) (range m)))))))


(defstruct player :actions :payoffs)


