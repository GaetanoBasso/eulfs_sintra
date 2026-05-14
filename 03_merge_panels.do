
********************************************************************************
*
*   03_merge_panels.do
*   Merge EU-LFS NUTS-2 panel (5-year periods) with Eurostat regional accounts
*   and retain only regions with consistent coverage across all four periods
*
*   Inputs:
*     ${finaldata}/EULFS/eulfs_nuts2_panel_5y.dta         (region × period)
*     ${cleaneddata}/eurostat/eurostat_nuts2_regaccounts.dta  (region × year)
*
*   Output:
*     ${finaldata}/working_nuts2_panel_5y.dta              (region × period)
*
*   Consistency filter: keep regions present in all 4 periods with non-missing
*     pop_fb_row, ss_instrument, gdp_real in every period
*
********************************************************************************

********************************************************************************
***  STEP 1: Collapse Eurostat annual data to 5-year period averages
********************************************************************************

use "${cleaneddata}/eurostat/eurostat_nuts2_regaccounts.dta", clear

gen byte period = .
replace period = 1 if inrange(year, 2005, 2009)
replace period = 2 if inrange(year, 2010, 2014)
replace period = 3 if inrange(year, 2015, 2019)
replace period = 4 if inrange(year, 2020, 2024)
drop if missing(period)

collapse (mean) gdp_real gdp_cp coe hhinc, by(region_2d period)

label define lperiod 1 "2005-2009" 2 "2010-2014" 3 "2015-2019" 4 "2020-2024"
label values period lperiod
label var gdp_real "GDP chain-linked real, MIO EUR (5-yr avg)"
label var gdp_cp   "GDP current prices, MIO EUR (5-yr avg)"
label var coe      "Compensation of employees, MIO EUR (5-yr avg)"
label var hhinc    "Net household disposable income, MIO EUR (5-yr avg)"

tempfile eurostat_5y
save `eurostat_5y'

********************************************************************************
***  STEP 2: Merge with EU-LFS panel
********************************************************************************

use "${finaldata}/EULFS/eulfs_nuts2_panel_5y.dta", clear

merge 1:1 region_2d period using `eurostat_5y', nogen

********************************************************************************
***  STEP 3: Save
********************************************************************************

sort country region_2d period
compress
save "${finaldata}/working_nuts2_panel_5y.dta", replace
