clear all
set mem 100m
set more off, perm

local recentpd 146
global base_dir "~/Dropbox/github/danhammer/empirical-paper"
global local_dir "~/Dropbox"

cd $local_dir

foreach iso in "mys" "idn" {
	use `iso'-clcount-`recentpd'.dta, clear
	keep lat lon
	sort lat lon
	outsheet using $base_dir/resources/`iso'-hits.csv, comma replace
}
