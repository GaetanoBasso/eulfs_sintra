
********************************************************************************
*
*   02_build_nuts2_panel.do
*   NUTS2-country panel with 5-year window averages, 2005-2024
*
*   Input:  ${cleaneddata}/EULFS/eulfs_byorigin_byedu_byregion_2004_2024.dta
*   Output: ${finaldata}/EULFS/eulfs_nuts2_panel_5y.dta
*
*   Panel structure:
*     Unit of observation: NUTS2 region × 5-year period
*     Periods: 2005-2009, 2010-2014, 2015-2019, 2020-2024
*     All continuous variables are 5-year simple averages of annual values
*
*   Foreign-born sub-groups used:
*     fb_eu    EUR_EU     - born in EU (includes NMS; EU-15/NMS split
*                           inconsistent across years and countries)
*     fb_eurne EUR_nonEU  - born in non-EU European countries (EFTA, other)
*     fb_adv              - advanced economies outside EU:
*                           EUR_nonEU + AME_N_OCE (N.America + Oceania)
*     fb_row              - rest of world:
*                           AFR_N_ASI_NME + ASI_ESSE + AME_LAT
*
*   NOTE on inactive 15-64: the inactive variable in the source data includes
*   individuals outside 15-64 by construction. Inactive 15-64 is derived here
*   as pop1564 - empl - unempl.
*
*   NOTE on education share: computed for 15-64 (no 25-64 age bin exists).
*   Tertiary = ISCED 5-8 (educ in "5","6","7","8"), denominator = 15-64 with
*   non-missing education.
*
*   Shift-share (Card 2001):
*     Groups: AFR_N_ASI_NME, ASI_ESSE, AME_LAT
*     Shares: stock (pop1564) at period start year in NUTS2 r /
*             total stock across ALL NUTS2 regions in ALL countries
*     Shift:  leave-one-out change over the 5-year window across all
*             other regions (all countries)
*     z_r = sum_g [ share_{r,g,t0} * (Delta_total_{g} - Delta_r_{g}) ]
*
********************************************************************************

use "${cleaneddata}/EULFS/eulfs_byorigin_byedu_byregion_2004_2024.dta", clear

drop if year < 2005
drop if missing(region_2d) | region_2d == ""

*** 5-year period
gen byte period = .
replace period = 1 if inrange(year, 2005, 2009)
replace period = 2 if inrange(year, 2010, 2014)
replace period = 3 if inrange(year, 2015, 2019)
replace period = 4 if inrange(year, 2020, 2024)
label define lperiod 1 "2005-2009" 2 "2010-2014" 3 "2015-2019" 4 "2020-2024"
label values period lperiod

gen int period_t0 = 2000 + 5 * period   // start year: 2005, 2010, 2015, 2020

********************************************************************************
***  SECTION A: Shift-share instrument (Card 2001)
***
***  Groups: AFR_N_ASI_NME, ASI_ESSE, AME_LAT
***  Shares: stock (pop1564) at t0 in NUTS2 r / total across ALL regions & countries
***  Shift:  leave-one-out total change (all other NUTS2 in all countries)
********************************************************************************

preserve

keep if inlist(countryb, "AFR_N_ASI_NME", "ASI_ESSE", "AME_LAT")

*** Annual region x group stocks (collapse across educ)
collapse (sum) pop1564, by(country region_2d countryb year period period_t0)

*** Extract stocks at period start (t0) and end (t0+4)
tempfile ss_annual
save `ss_annual'

use `ss_annual', clear
keep if year == period_t0
rename pop1564 stock_t0
keep country region_2d countryb period stock_t0
tempfile ss_t0
save `ss_t0'

use `ss_annual', clear
gen period_t1 = period_t0 + 4
keep if year == period_t1
rename pop1564 stock_t1
keep country region_2d countryb period stock_t1
tempfile ss_t1
save `ss_t1'

*** Merge start and end stocks
use `ss_t0', clear
merge 1:1 country region_2d countryb period using `ss_t1', nogen

*** Total stocks across ALL regions and ALL countries (leave-one-out denominator)
bysort countryb period: egen total_t0 = total(stock_t0)
bysort countryb period: egen total_t1 = total(stock_t1)

*** Shares (at t0) and leave-one-out shifts
gen share_rg    = stock_t0 / total_t0              // share of group g in region r at t0
gen delta_total = total_t1 - total_t0              // total change across all regions
gen delta_r     = stock_t1 - stock_t0              // change in region r
gen delta_excl  = delta_total - delta_r            // leave-one-out: all other regions

*** Shift-share term; sum across groups for the instrument
gen ss_term = share_rg * delta_excl
collapse (sum) ss_instrument = ss_term, by(country region_2d period)

tempfile ss_final
save `ss_final'

restore

********************************************************************************
***  SECTION B: Main panel variables
********************************************************************************

*** Valid country of birth (exclude unknown/missing codes)
gen valid_cb = !inlist(countryb, "", "NO ANSWER", "999") & !missing(countryb)

*** Origin group indicators
*   nat    : native born
*   fb     : all foreign born (valid countryb)
*   fb_eu  : born in EU (EUR_EU; includes NMS)
*   fb_eurne: born in non-EU European countries (EUR_nonEU: EFTA, other)
*   fb_adv : advanced economies outside EU = EUR_nonEU + AME_N_OCE
*   fb_row : rest of world = AFR_N_ASI_NME + ASI_ESSE + AME_LAT
gen nat     = (countryb == "NAT")
gen fb      = (countryb != "NAT") & valid_cb
gen fb_eu   = (countryb == "EUR_EU")
gen fb_eurne= (countryb == "EUR_nonEU")
gen fb_adv  = inlist(countryb, "EUR_nonEU", "AME_N_OCE")
gen fb_row  = inlist(countryb, "AFR_N_ASI_NME", "ASI_ESSE", "AME_LAT")

*** Tertiary education (ISCED 5-8) and valid education indicator
gen tert       = inlist(educ, "5", "6", "7", "8")
gen educ_valid = educ != "" & !missing(educ)

*** Population by group (all ages)
gen pop_tot    = pop * valid_cb
gen pop_nat    = pop * nat
gen pop_fb     = pop * fb
gen pop_fb_eu  = pop * fb_eu
gen pop_fb_eurne = pop * fb_eurne
gen pop_fb_adv = pop * fb_adv
gen pop_fb_row = pop * fb_row

*** Population 15-64 by group
gen pop1564_tot    = pop1564 * valid_cb
gen pop1564_nat    = pop1564 * nat
gen pop1564_fb     = pop1564 * fb
gen pop1564_fb_eu  = pop1564 * fb_eu
gen pop1564_fb_eurne = pop1564 * fb_eurne
gen pop1564_fb_adv = pop1564 * fb_adv
gen pop1564_fb_row = pop1564 * fb_row

*** Employment 15-64 by group
gen empl_tot   = empl   * valid_cb
gen empl_nat   = empl   * nat
gen empl_fb    = empl   * fb

gen unempl_tot = unempl * valid_cb
gen unempl_nat = unempl * nat
gen unempl_fb  = unempl * fb

*** Education: numerator (tertiary 15-64) and denominator (valid educ 15-64)
gen ednum   = pop1564 * valid_cb * tert
gen eddenom = pop1564 * valid_cb * educ_valid

*** Step 1: sum across countryb x educ → annual region totals
collapse (sum)  pop_tot pop_nat pop_fb pop_fb_eu pop_fb_eurne pop_fb_adv pop_fb_row     ///
                pop1564_tot pop1564_nat pop1564_fb pop1564_fb_eu pop1564_fb_eurne        ///
                pop1564_fb_adv pop1564_fb_row                                            ///
                empl_tot empl_nat empl_fb                                                ///
                unempl_tot unempl_nat unempl_fb                                          ///
                ednum eddenom                                                             ///
         (max)  flag_missing_countryb,                                                   ///
         by(country region_2d year period)

*** Inactive 15-64 by group (derived; source inactive var includes non-15-64)
gen inactive_tot = pop1564_tot - empl_tot - unempl_tot
gen inactive_nat = pop1564_nat - empl_nat - unempl_nat
gen inactive_fb  = pop1564_fb  - empl_fb  - unempl_fb

*** Step 2: average across years within period
collapse (mean) pop_tot pop_nat pop_fb pop_fb_eu pop_fb_eurne pop_fb_adv pop_fb_row     ///
                pop1564_tot pop1564_nat pop1564_fb pop1564_fb_eu pop1564_fb_eurne        ///
                pop1564_fb_adv pop1564_fb_row                                            ///
                empl_tot empl_nat empl_fb                                                ///
                unempl_tot unempl_nat unempl_fb                                          ///
                inactive_tot inactive_nat inactive_fb                                    ///
                ednum eddenom                                                             ///
         (max)  flag_missing_countryb,                                                   ///
         by(country region_2d period)

*** Education share: share of 15-64 with tertiary educ (among non-missing educ)
gen sh_tert = ednum / eddenom
drop ednum eddenom

*** Merge shift-share instrument
merge 1:1 country region_2d period using `ss_final', nogen

*** Restore period start year (dropped by second collapse)
gen int period_t0 = 2000 + 5 * period

sort country region_2d period

********************************************************************************
***  Variable labels
********************************************************************************

label values period lperiod

label var country              "Country code (ISO2)"
label var region_2d            "NUTS2 region code"
label var period               "5-year period (1=2005-09, 2=2010-14, 3=2015-19, 4=2020-24)"
label var period_t0            "First year of 5-year window"
label var flag_missing_countryb "=1 if country-of-birth detail unavailable (ncountry<12)"

label var pop_tot              "Total population, all (5-yr avg)"
label var pop_nat              "Total population, native born"
label var pop_fb               "Total population, foreign born"
label var pop_fb_eu            "Total population, EU born (EUR_EU; incl. NMS)"
label var pop_fb_eurne         "Total population, non-EU European born (EUR_nonEU)"
label var pop_fb_adv           "Total population, advanced econ excl. EU (EUR_nonEU + AME_N_OCE)"
label var pop_fb_row           "Total population, rest of world (AFR_N_ASI_NME + ASI_ESSE + AME_LAT)"

label var pop1564_tot          "Population 15-64, all (5-yr avg)"
label var pop1564_nat          "Population 15-64, native born"
label var pop1564_fb           "Population 15-64, foreign born"
label var pop1564_fb_eu        "Population 15-64, EU born"
label var pop1564_fb_eurne     "Population 15-64, non-EU European born"
label var pop1564_fb_adv       "Population 15-64, advanced econ excl. EU"
label var pop1564_fb_row       "Population 15-64, rest of world"

label var empl_tot             "Employed 15-64, all (5-yr avg)"
label var empl_nat             "Employed 15-64, native born"
label var empl_fb              "Employed 15-64, foreign born"

label var unempl_tot           "Unemployed 15-64, all (5-yr avg)"
label var unempl_nat           "Unemployed 15-64, native born"
label var unempl_fb            "Unemployed 15-64, foreign born"

label var inactive_tot         "Inactive 15-64 (= pop1564 - empl - unempl), all (5-yr avg)"
label var inactive_nat         "Inactive 15-64, native born"
label var inactive_fb          "Inactive 15-64, foreign born"

label var sh_tert              "Share of 15-64 with tertiary educ (ISCED 5-8), among non-missing educ"

label var ss_instrument        "Card (2001) shift-share: groups AFR_N_ASI_NME + ASI_ESSE + AME_LAT, leave-one-out across all regions and countries"

********************************************************************************
***  Save
********************************************************************************

compress
save "${finaldata}/EULFS/eulfs_nuts2_panel_5y.dta", replace
