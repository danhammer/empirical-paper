/* This script tags each pixel with a cluster and saves the output to
a separate .dta file by interval number.  Two input files are required
for this script: (1) a text file that is the result from hfs-texline
with the identifying information for each pixel that eventually
registers as a hit, and the period when it first exceeded the pre-set
probability threshold; (2) a csv file that associates each GADM
integer ID to the three-character ISO code for Indonesia and
Malaysia. */

clear all
set mem 100m
set more off, perm

/* set parameters: (1) percentage of the data set to use, full data set is 1  */
/* (2) a threshold that defines a cluster in degrees. */
global perc 1
global cut_thresh 0.01

/* base directory is the github empirical-paper project */
global base_dir "D:\Users\danhammer\My Documents\Dropbox\github\danhammer\empirical-paper"
*global base_dir "~/Dropbox/github/danhammer/empirical-paper"
global temp_dir "$base_dir\data\temp"
global out_dir  "$base_dir\data\staging\empirical-out"

cd "$base_dir"

insheet using "$base_dir/data/raw/borneo-hits/full-hits.txt", clear
rename v1 h
rename v2 v
rename v3 s
rename v4 l
rename v5 lat
rename v6 lon
rename v7 gadm
rename v8 pd
sort gadm
save "$temp_dir/full_temp", replace

insheet using "$base_dir/data/raw/admin-map.csv", comma clear
rename v1 iso
rename v2 gadm
sort gadm
save "$temp_dir/admin_temp", replace

use "$temp_dir/full_temp", clear
merge gadm using "$temp_dir/admin_temp"
keep if _m == 3
drop _m
preserve

/* prep data for overall alerts */
keep if iso == "IDN"
drop gadm iso
save "$temp_dir/idn_hits", replace

/* prep data for overall alerts */
restore
keep if iso == "MYS"
drop gadm iso
save "$temp_dir/mys_hits", replace

/* generate total alerts for MYS and IDN */
foreach iso in "mys" "idn" {
	use "$temp_dir/`iso'_hits", clear
	gen `iso'_alert = 1
	collapse (count) `iso'_alert, by(pd)
	drop if pd == 0
	sort pd 
	save "$temp_dir/`iso'_rate", replace
}

/* create mata data structure to store results */
qui sum pd
global max `=r(max)'
m: idn = J($max,1,-9999)
m: mys = J($max,1,-9999)

foreach iso in "mys" "idn" {
	use "$temp_dir/`iso'_hits", clear
	
	/* randomly sample from the FORMA hits; for all data, set  */
	/* local variable perc to 1 */
	gen random = runiform()
	keep if random <= $perc
	drop random
	save "$temp_dir/cl_temp", replace
	
	forvalues i = 1/$max {
		use "$temp_dir/cl_temp", clear
		keep if pd <= `i'
		cluster singlelinkage lat lon
		cluster generate cl_`i' = cut($cut_thresh)	
		drop _cl*
		by cl_`i', sort: gen count_`i' = _N
		qui sum count_`i' if count_`i' >= 2
		m: `iso'[`i'] = `=r(N)'
		sort h v s l
		save "$out_dir/`iso'-clcount-`i'.dta", replace
	}
}


