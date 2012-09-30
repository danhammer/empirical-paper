clear all
set mem 100m
set more off, perm

local perc 0.03
global base_dir "C:/Users/danhammer/Dropbox/github/danhammer/empirical-paper"
global base_dir "~/Dropbox/github/danhammer/empirical-paper"
global temp_dir "/tmp/emp"

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

use $temp_dir/idn_hits, clear
gen idn_alert = 1
collapse (count) idn_alert, by(pd)
drop if pd == 0
sort pd 
save $temp_dir/idn_rate, replace

use $temp_dir/mys_hits, clear
gen mys_alert = 1
collapse (count) mys_alert, by(pd)
drop if pd == 0
sort pd 
save $temp_dir/mys_rate, replace

qui sum pd
global max `=r(max)'
m: idn = J($max,1,-9999)
m: mys = J($max,1,-9999)

use $temp_dir/idn_hits, clear
gen random = runiform()
keep if random <= `perc'
drop random
save $temp_dir/new_temp, replace
forvalues i=46/$max {
	use $temp_dir/new_temp, clear
	keep if pd <= `i'
	cluster singlelinkage lat lon
	cluster generate cl = cut(0.1)	
	drop _cl*
	by cl, sort: gen count = _N
	keep if count <= 2
	qui sum count
	local newcl `=r(N)'
	m: idn[`i'] = `newcl'
}

clear
set obs $max
m: st_addvar("int","idn")
m: st_store(.,"idn",idn)
gen pd = _n
sort pd
merge pd using $temp_dir/idn_rate
drop _m
gen prop_idn = idn/idn_alert
save $temp_dir/cl_idn, replace

use $temp_dir/mys_hits, clear
gen random = runiform()
keep if random <= `perc'
drop random
save $temp_dir/new_temp, replace
forvalues i=46/$max {
	use $temp_dir/new_temp, clear
	keep if pd <= `i'
	cluster singlelinkage lat lon
	cluster generate cl = cut(0.1)	
	drop _cl*
	by cl, sort: gen count = _N
	keep if count <= 2
	qui sum count
	local newcl `=r(N)'
	m: mys[`i'] = `newcl'
}

use $temp_dir/cl_idn, clear
set obs $max
m: st_addvar("int","mys")
m: st_store(.,"mys",mys)
sort pd
merge pd using $temp_dir/mys_rate
drop _m
gen prop_mys = mys/mys_alert
save $base_dir/write-up/data/processed/total_clusters, replace
graph twoway (line prop_idn pd if pd > 46) (line prop_mys pd if pd > 46), xline(116)
* graph export $base_dir/src/do/prop_rate.png, replace

drop if pd < 46
keep pd prop_*
rename prop_idn prop1
rename prop_mys prop0
reshape long prop, i(pd) j(cntry)
gen post = pd >= 116
gen i_pd_post = pd * post
gen i_pd_cntry = pd * cntry
gen i_post_cntry = post * cntry
gen i_pd_cntry_post = pd * cntry * post

reg prop pd post cntry i*
outreg2 using $base_dir/write-up/tables/regout.tex, replace tex(frag)
save $base_dir/write-up/data/processed/final, replace

predict z
* graph twoway (line prop pd if pd > 46 & cntry==1) (line prop pd if pd > 46 & cntry==0) (line z pd if pd > 46  & cntry==1) (line z pd if pd > 46  & cntry==0), xline(116)
* graph export $base_dir/write-up/images/pred_prop.png, replace 


* pd 47 when the study should start, 2008-01-01
* pd 100 when the moratorium was first announced, 2010-05-01
* pd 116 when the moratorium was supposed to be implemented, 2011-01-01
* pd 123 when the moratorium was actually enacted, 2010-06-01

/* use $base_dir/src/do/total_clusters	, clear */
/* set scheme s1color */
/* graph twoway (line idn pd if pd >= 47), xline(100 103 116 119 123 126) */
/* graph export $base_dir/write-up/images/new-idn7.png, replace */
/* graph twoway (line mys pd if pd >= 47), xline(100 103 116 119 123 126) */
/* graph export $base_dir/write-up/images/new-mys7.png, replace */

/* graph twoway (line idn_alert pd if pd >= 47) (line mys_alert pd if pd >= 47), xline(100 103 116 119 123 126) */
/* graph export $base_dir/write-up/images/total-alerts7.png, replace */
/* graph twoway (line prop_idn pd if pd >= 47) (line prop_mys pd if pd >= 47), xline(100 103 116 119 123 126) */
/* graph export $base_dir/write-up/images/both-props7.png, replace */





