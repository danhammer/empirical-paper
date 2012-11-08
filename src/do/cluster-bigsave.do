clear all
set mem 100m
set more off, perm

local perc 1
global base_dir "C:/Users/danhammer/Dropbox/github/danhammer/empirical-paper"
global base_dir "~/Dropbox/github/danhammer/empirical-paper"
global temp_dir "/tmp/emp"
global out_dir "/tmp/out"

cd $base_dir

insheet using $base_dir/write-up/data/raw/part-00000.txt, clear
rename v1 lat
rename v2 lon
rename v3 gadm
rename v4 pd
sort gadm
save $temp_dir/full_temp, replace

insheet using $base_dir/write-up/data/raw/admin-map.csv, comma clear
rename v1 iso
rename v2 gadm
sort gadm
save $temp_dir/admin_temp, replace

use $temp_dir/full_temp, clear
merge gadm using $temp_dir/admin_temp
keep if _m == 3
drop _m
preserve

keep if iso == "IDN"
drop gadm iso
save $temp_dir/idn_hits, replace

restore
keep if iso == "MYS"
drop gadm iso
save $temp_dir/mys_hits, replace

foreach iso in "mys" "idn" {
	use $temp_dir/`iso'_hits, clear
	gen `iso'_alert = 1
	collapse (count) `iso'_alert, by(pd)
	drop if pd == 0
	sort pd 
	save $temp_dir/`iso'_rate, replace
}

* create mata data structure to store results
qui sum pd
global max `=r(max)'
m: idn = J($max,1,-9999)
m: mys = J($max,1,-9999)

foreach iso in "idn" {
	use $temp_dir/`iso'_hits, clear
	
	* randomly sample from the FORMA hits; for all data, set 
	* local variable perc to 1
	gen random = runiform()
	keep if random <= `perc'
	drop random
	save $temp_dir/cl_temp, replace
	
	forvalues i = 120/120 {
		use $temp_dir/cl_temp, clear
		keep if pd <= `i'
		cluster singlelinkage lat lon
		cluster generate cl_`i' = cut(0.2)	
		drop _cl*
		by cl_`i', sort: gen count_`i' = _N
		qui sum count_`i' if count_`i' >= 2
		m: `iso'[`i'] = `=r(N)'
		sort lat lon
		save $out_dir/`iso'-clcount-`i'.dta, replace
	}
}

* move mata results into stata, merge in full hits
clear
set obs $max
gen pd = _n
mata
st_addvar("int","idn")
st_store(.,"idn",idn)
st_addvar("int","mys")
st_store(.,"mys",mys)
end

foreach iso in "mys" "idn" {
	sort pd
	merge pd using $temp_dir/`iso'_rate
	drop _m
	gen `iso'_prop = `iso'/`iso'_alert
	sort pd
}

save $out_dir/total-rates.dta, replace









