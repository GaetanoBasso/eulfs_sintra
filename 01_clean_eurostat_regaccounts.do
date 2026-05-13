
********************************************************************************
*
*   01_clean_eurostat_regaccounts.do
*   Download, clean, and build NUTS-2 regional accounts panel from Eurostat
*
*   Series:
*     NAMA_10R_3GDP / A.MIO_EUR       NUTS-3 GDP, current prices
*     NAMA_10R_3GDP / A.MIO_EUR_PYP   NUTS-3 GDP, previous-year prices
*     NAMA_10R_2COE / A.MIO_EUR.TOTAL NUTS-2 compensation of employees
*     NAMA_10R_2HHINC / A.MIO_EUR.BAL.B6N  NUTS-2 net household disp. income
*
*   All raw TSNAME strings have the form: DATASET.FREQ.UNIT[.SUB...].GEO
*   The geo code is always the last dot-separated segment.
*
*   Chain-linking algorithm (base year = `baseyear'):
*     1. Keep NUTS-3 geo codes (strlen == 5); derive NUTS-2: substr(geo,1,4)
*     2. Sum NUTS-3 CP and PYP to NUTS-2 by collapsing on region_2d × year
*     3. g(r,t)        = GDP_pyp(r,t) / GDP_cp(r,t−1)   [growth rate]
*     4. Index(r,B)    = 1  (B = `baseyear'; fallback = first available year)
*        Index(r,t)    = Index(r,t−1) × g(r,t)           [forward]
*        Index(r,t−1)  = Index(r,t)   / g(r,t)           [backward]
*     5. GDP_real(r,t) = GDP_cp(r,B) × Index(r,t)
*
*   Output:
*     ${cleaneddata}/eurostat/eurostat_nuts2_regaccounts.dta
*     Unit: NUTS-2 region × year
*     Variables: country, region_2d, year, gdp_real, gdp_cp, gdp_pyp, coe, hhinc
*
********************************************************************************

local baseyear 2000

********************************************************************************
***  BLOCK 1: NUTS-3 GDP at current prices
********************************************************************************

getTimeSeries EUROSTAT NAMA_10R_3GDP/A.MIO_EUR. "" "" 0 0
destring _all, replace

gen geo   = substr(TSNAME, strrpos(TSNAME, ".") + 1, .)
rename DATE  year
rename VALUE gdp_cp_n3

keep if strlen(geo) == 5          // NUTS-3 codes only (5 characters)
gen region_2d = substr(geo, 1, 4) // parent NUTS-2
keep region_2d year gdp_cp_n3

collapse (sum) gdp_cp_n3, by(region_2d year)  // sum to NUTS-2

tempfile gdp_cp
save `gdp_cp'

********************************************************************************
***  BLOCK 2: NUTS-3 GDP at previous-year prices
********************************************************************************

getTimeSeries EUROSTAT NAMA_10R_3GDP/A.MIO_EUR_PYP. "" "" 0 0
destring _all, replace

gen geo   = substr(TSNAME, strrpos(TSNAME, ".") + 1, .)
rename DATE  year
rename VALUE gdp_pyp_n3

keep if strlen(geo) == 5
gen region_2d = substr(geo, 1, 4)
keep region_2d year gdp_pyp_n3

collapse (sum) gdp_pyp_n3, by(region_2d year)  // sum to NUTS-2

********************************************************************************
***  BLOCK 3: Chain-link to obtain real GDP at NUTS-2
********************************************************************************

merge 1:1 region_2d year using `gdp_cp', nogen
sort region_2d year

*** Rename to working names
rename gdp_cp_n3  gdp_cp
rename gdp_pyp_n3 gdp_pyp

*** Lagged current-price GDP: only use if years are consecutive (no gap)
by region_2d: gen gdp_cp_lag = gdp_cp[_n-1] if year == year[_n-1] + 1

*** Growth rate: g(r,t) = PYP(r,t) / CP(r,t-1)
gen g = gdp_pyp / gdp_cp_lag

*** Initialise chain-link index
gen index = .
by region_2d (year): replace index = 1 if year == `baseyear'
* For regions with no data at base year, anchor at their first available year
by region_2d (year): replace index = 1 if year == year[1] & missing(index)

*** Forward propagation: Index(t) = Index(t-1) * g(t)
* Each iteration extends the chain one year forward; 30 covers 2000-2030
forvalues i = 1(1)30 {
    by region_2d (year): replace index = index[_n-1] * g ///
        if missing(index) & !missing(g) & !missing(index[_n-1])
}

*** Backward propagation: Index(t) = Index(t+1) / g(t+1)
* After gsort descending, [_n-1] refers to year t+1 within region
gsort region_2d -year
forvalues i = 1(1)30 {
    by region_2d: replace index = index[_n-1] / g[_n-1] ///
        if missing(index) & !missing(g[_n-1]) & !missing(index[_n-1])
}
sort region_2d year

*** Anchor current-price level at the year where index = 1
gen   _anchor_cp = gdp_cp if index == 1
* Broadcast anchor value to all years of the region
bysort region_2d (_anchor_cp): replace _anchor_cp = _anchor_cp[_N]

*** Chain-linked real GDP (MIO EUR, prices of base year)
gen gdp_real = _anchor_cp * index
drop _anchor_cp g gdp_cp_lag index

label var gdp_cp   "GDP current prices, MIO EUR (NUTS-3 summed to NUTS-2)"
label var gdp_pyp  "GDP previous-year prices, MIO EUR (NUTS-3 summed to NUTS-2)"
label var gdp_real "GDP chain-linked real, MIO EUR (base = `baseyear' current prices)"

tempfile gdp_final
save `gdp_final'

********************************************************************************
***  BLOCK 4: Compensation of employees (NUTS-2)
********************************************************************************

getTimeSeries EUROSTAT NAMA_10R_2COE/A.MIO_EUR.TOTAL. "" "" 0 0
destring _all, replace

gen region_2d = substr(TSNAME, strrpos(TSNAME, ".") + 1, .)
rename DATE  year
rename VALUE coe

keep if strlen(region_2d) == 4   // NUTS-2 codes only
keep region_2d year coe

label var coe "Compensation of employees, total, MIO EUR (NUTS-2)"

tempfile coe_data
save `coe_data'

********************************************************************************
***  BLOCK 5: Net household disposable income (NUTS-2)
********************************************************************************

getTimeSeries EUROSTAT NAMA_10R_2HHINC/A.MIO_EUR.BAL.B6N. "" "" 0 0
destring _all, replace

gen region_2d = substr(TSNAME, strrpos(TSNAME, ".") + 1, .)
rename DATE  year
rename VALUE hhinc

keep if strlen(region_2d) == 4   // NUTS-2 codes only
keep region_2d year hhinc

label var hhinc "Net household disposable income (B6N balance), MIO EUR (NUTS-2)"

tempfile hhinc_data
save `hhinc_data'

********************************************************************************
***  BLOCK 6: Build NUTS-2 × year panel
********************************************************************************

use `gdp_final', clear
merge 1:1 region_2d year using `coe_data',  nogen keep(1 3)
merge 1:1 region_2d year using `hhinc_data', nogen keep(1 3)

*** Country code from NUTS-2 prefix
gen country = substr(region_2d, 1, 2)

*** Keep only years from 2000 onwards (sparse/missing before that in most series)
keep if year >= 2000

sort country region_2d year

order country region_2d year gdp_real gdp_cp gdp_pyp coe hhinc

label var country   "Country code (ISO2)"
label var region_2d "NUTS-2 region code"
label var year      "Year"

compress
save "${cleaneddata}/eurostat/eurostat_nuts2_regaccounts.dta", replace
