
********************************************************************************
*
*   01_clean_eurostat_regaccounts.do
*   Download, clean, and build NUTS-2 regional accounts panel from Eurostat
*
*   Series:
*     NAMA_10R_2GDP   / A.MIO_EUR     NUTS-2 GDP, current prices (MIO EUR)
*     NAMA_10R_2GVAGR / A.PCH_PRE     NUTS-2 GVA growth rate, % change vs previous year
*     NAMA_10R_2COE   / A.MIO_EUR.TOTAL   NUTS-2 compensation of employees (MIO EUR)
*     NAMA_10R_2HHINC / A.MIO_EUR.BAL.B6N NUTS-2 net household disposable income (MIO EUR)
*
*   All TSNAME strings have the form: DATASET.FREQ.UNIT[.SUB...].GEO
*   The geo code is always the last dot-separated segment.
*   NUTS-2 regions have 4-character geo codes (e.g. AT11, DE21, FR10).
*
*   Chain-linking algorithm (base year = `baseyear'):
*     1. g(r,t)        = 1 + GVA_growth_rate(r,t) / 100
*     2. Index(r,B)    = 1   (B = `baseyear'; fallback = first available year)
*        Index(r,t)    = Index(r,t-1) * g(r,t)          [forward propagation]
*        Index(r,t-1)  = Index(r,t)   / g(r,t)          [backward propagation]
*     3. GDP_real(r,t) = GDP_cp(r,B) * Index(r,t)
*
*   GVA growth rates are used in place of GDP growth rates; at NUTS-2 level
*   taxes minus subsidies on products are not separately observed, and GVA
*   growth is the standard Eurostat approximation for real regional GDP growth.
*
*   Output:
*     ${cleaneddata}/eurostat/eurostat_nuts2_regaccounts.dta
*     Unit: NUTS-2 region × year
*     Variables: country, region_2d, year, gdp_real, gdp_cp, coe, hhinc
*
********************************************************************************

local baseyear 2000

********************************************************************************
***  BLOCK 1: GDP at current prices (NUTS-2)
********************************************************************************

getTimeSeries EUROSTAT NAMA_10R_2GDP/A.MIO_EUR. "" "" 0 0
destring _all, replace

gen region_2d = substr(TSNAME, strrpos(TSNAME, ".") + 1, .)
rename DATE  year
rename VALUE gdp_cp

keep if strlen(region_2d) == 4     // NUTS-2 codes only
keep region_2d year gdp_cp

label var gdp_cp "GDP current prices, MIO EUR (NUTS-2, NAMA_10R_2GDP)"

tempfile gdp_cp
save `gdp_cp'

********************************************************************************
***  BLOCK 2: GVA growth rate — % change vs previous year (NUTS-2)
********************************************************************************

getTimeSeries EUROSTAT NAMA_10R_2GVAGR/A.PCH_PRE. "" "" 0 0
destring _all, replace

gen region_2d = substr(TSNAME, strrpos(TSNAME, ".") + 1, .)
rename DATE  year
rename VALUE gva_gr

keep if strlen(region_2d) == 4
keep region_2d year gva_gr

********************************************************************************
***  BLOCK 3: Chain-link to obtain real GDP
********************************************************************************

merge 1:1 region_2d year using `gdp_cp', nogen
sort region_2d year

*** Growth factor: g(r,t) = 1 + pct_change(r,t)/100
gen g = 1 + gva_gr / 100

*** Initialise chain-link index
gen index = .
by region_2d (year): replace index = 1 if year == `baseyear'
* For regions with no data at base year, anchor at their first available year
by region_2d (year): replace index = 1 if year == year[1] & missing(index)

*** Forward propagation: Index(t) = Index(t-1) * g(t)
forvalues i = 1(1)30 {
    by region_2d (year): replace index = index[_n-1] * g ///
        if missing(index) & !missing(g) & !missing(index[_n-1])
}

*** Backward propagation: Index(t) = Index(t+1) / g(t+1)
* After gsort descending, [_n-1] within region refers to the higher year
gsort region_2d -year
forvalues i = 1(1)30 {
    by region_2d: replace index = index[_n-1] / g[_n-1] ///
        if missing(index) & !missing(g[_n-1]) & !missing(index[_n-1])
}
sort region_2d year

*** Anchor current-price level at the year where index = 1
gen   _anchor_cp = gdp_cp if index == 1
* Broadcast anchor value to all years within region (missing sorts last)
bysort region_2d (_anchor_cp): replace _anchor_cp = _anchor_cp[_N]

*** Chain-linked real GDP (MIO EUR, prices of base year)
gen gdp_real = _anchor_cp * index
drop _anchor_cp g index gva_gr

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

keep if strlen(region_2d) == 4
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

keep if strlen(region_2d) == 4
keep region_2d year hhinc

label var hhinc "Net household disposable income (B6N balance), MIO EUR (NUTS-2)"

tempfile hhinc_data
save `hhinc_data'

********************************************************************************
***  BLOCK 6: Build NUTS-2 × year panel
********************************************************************************

use `gdp_final', clear
merge 1:1 region_2d year using `coe_data',   nogen keep(1 3)
merge 1:1 region_2d year using `hhinc_data', nogen keep(1 3)

*** Country code from NUTS-2 prefix
gen country = substr(region_2d, 1, 2)

keep if year >= 2000

sort country region_2d year
order country region_2d year gdp_real gdp_cp coe hhinc

label var country   "Country code (ISO2)"
label var region_2d "NUTS-2 region code"
label var year      "Year"

compress
save "${cleaneddata}/eurostat/eurostat_nuts2_regaccounts.dta", replace
