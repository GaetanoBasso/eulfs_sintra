
/*
*** Up until 2020
local names_files: dir "${EULFS2020}" files "*" // Local: list - all files in a folder
di "File names in folder ${EULFS2020} are: " `names_files'
 
foreach lvl_names_files of local names_files {
	use ${EULFS2020}/`lvl_names_files', clear
	renvars *, lower
	replace countryb=trim(countryb)
	gen nativeborn=substr(countryb,1,3)=="000"
	gen foreignborn=1-nativeborn
	di "******************"
	di "`lvl_names_files'"
	tab countryb
	di "******************"
	scalar ncountry=`r(r)' 
	gen detailcountryb=ncountry
	destring year, replace
	collapse (sum) *born (max) detailcountryb [pw=coeff], by(year country)
	cap compress
	cap saveold ${temp}/`lvl_names_files', replace
}

clear all
foreach lvl_names_files of local names_files {
	append using ${temp}/`lvl_names_files'
}
gen flag_missing_migration=detailcountryb<=1
replace nativeborn=foreignborn if flag_missing_migration==1
replace foreignborn=. if flag_missing_migration==1
gen share_foreignborn=foreignborn/(nativeborn+foreignborn)
sort country year
list country year if flag==1, clean
save ${cleaneddata}/EULFS/eulfs_summary_1983_2020.dta, replace

clear all
cd ${temp}
foreach lvl_names_files of local names_files {
	!rm `lvl_names_files'
}
*/

*** From 2021
local names_files: dir "${EULFS2024}" files "*" // Local: list - all files in a folder
di "File names in folder ${EULFS2024} are: " `names_files'
 
foreach lvl_names_files of local names_files {
	import delimited using ${EULFS2024}/`lvl_names_files', clear varnames(1)
	cap renvars *, lower
	tostring countryb, replace
	replace countryb="" if countryb=="."
	replace countryb=trim(countryb)
	qui tab countryb
	scalar ncountry=`r(r)' 
	gen nativeborn=substr(countryb,1,3)=="000"|substr(countryb,1,3)=="NAT"|countryb==""
	replace nativeborn=1 if ncountry==1&countryb=="NO ANSWER"
	gen foreignborn=1-nativeborn
	di "******************"
	di "`lvl_names_files'"
	tab countryb
	di "******************"
	scalar ncountry=`r(r)' 
	gen detailcountryb=ncountry
	destring year, replace
	collapse (sum) *born (max) detailcountryb [pw=coeffy], by(year country)
	cap compress
	cap saveold ${temp}/`lvl_names_files', replace
}

clear all
foreach lvl_names_files of local names_files {
	append using ${temp}/`lvl_names_files'
}
gen flag_missing_migration=detailcountryb<=1
gen flag_detailed_migration=detailcountryb>=10&detailcountryb!=.
replace nativeborn=foreignborn if flag_missing_migration==1
replace foreignborn=. if flag_missing_migration==1
sort country year
list country year if flag_missing_migration==1, clean
save ${cleaneddata}/EULFS/eulfs_summary_1983_2024.dta, replace

*************************************************************
*	Graphs on foreign born share in eu27, eu14 and big4
*************************************************************
use ${cleaneddata}/EULFS/eulfs_summary_1983_2024.dta, clear

keep if flag_missing_migration==0
gen eu27 = inlist(country,"AT","BE","BG","HR","CY","CZ","DK","EE","FI")
replace eu27 = inlist(country,"FR","DE","GR","HU","IE","IT","LV","LT","LU") if eu27==0
replace eu27 = inlist(country,"MT","NL","PL","PT","RO","SK","SI","ES","SE") if eu27==0
keep if eu27==1

gen eu14 = inlist(country, "AT","BE","DK","FI","FR","DE","GR","IE")
replace eu14 = inlist(country,"IT","LU","NL","PT","ES","SE") if eu14==0
gen it = inlist(country, "IT")
gen fr = inlist(country, "FR")
gen de = inlist(country, "DE")
gen es = inlist(country, "ES")

table country, stat(min year) stat(max year)
table country if flag_detailed_migration==1, stat(min year) stat(max year)

foreach j in eu27 eu14 es fr de it {
	preserve
		keep if `j'==1
		collapse (sum) native foreign, by(year)
		if "`j'"=="eu27"|"`j'"=="eu14"|"`j'"=="fr"|"`j'"=="de" {
			keep if year>=2004
		}
		summ year 
		local miny=r(min)
		local maxy=r(max)
		gen sh_fborn=100*foreign/(native+foreign)
		sort year
		tw line sh_fborn year, title("`j'") name(`j', replace)
		graph export ${vizdata}/eulfs_`j'_series_`miny'_`maxy'.png, replace
	restore
}

********************************************************************
***	Cleaning temp files
********************************************************************
clear all
cd ${temp}
foreach lvl_names_files of local names_files {
	!rm `lvl_names_files'
}
