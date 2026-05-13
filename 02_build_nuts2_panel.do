
********************************************************************************
*
*   02_build_nuts2_panel.do
*   NUTS2-country panel with 5-year window averages, 2005-2024
*
*   Input:  ${cleaneddata}/EULFS/eulfs_byorigin_byedu_byregion_2004_2024.dta
*   Output: ${finaldata}/EULFS/eulfs_nuts2_panel_5y.dta
*
*   NOTE on EU-15 identification: the cleaning dofile merges EU-15 and new
*   member state (NMS) born into a single EUR_EU category. EU-15 born cannot
*   be separately identified in the output data. The variable fb_eu therefore
*   proxies "EU-15 born" but includes NMS born (upward bias). NMS born are
*   consequently absent from fb_noneu15 and fb_adv. To correct this, the
*   cleaning dofile would need to preserve the EU15/NMS split available in the
*   raw files for 2005-2019 (no EU-15 group code exists in the 2020+ format).
*
*   NOTE on inactive 15-64: the inactive variable in the source data includes
*   all individuals outside the 15-64 age band (by construction in the cleaning
*   code). Inactive 15-64 is therefore derived here as pop1564 - empl - unempl.
*
*   NOTE on education share: the share with tertiary education is computed for
*   the 15-64 age group (pop1564) since no 25-64 age bin exists in the data.
*   Tertiary education = ISCED levels 5-8 (educ in "5","6","7","8").
*
*   NOTE on shift-share: the leave-one-out national stock excludes only the
*   NUTS2 region of analysis (within-country leave-one-out). This is the
*   standard Card (2001) implementation for within-country panels. For a
*   multi-country EU panel, an alternative is to use shifts from other countries.
*
********************************************************************************

use "${cleaneddata}/EULFS/eulfs_byorigin_byedu_byregion_2004_2024.dta", clear

drop if year < 2005
drop if missing(region_2d) | region_2d == ""

*** 5-year period variable
gen byte period = .
replace period = 1 if inrange(year, 2005, 2009)
replace period = 2 if inrange(year, 2010, 2014)
replace period = 3 if inrange(year, 2015, 2019)
replace period = 4 if inrange(year, 2020, 2024)
label define lperiod 1 "2005-2009" 2 "2010-2014" 3 "2015-2019" 4 "2020-2024"
label values period lperiod

gen int period_t0 = 2000 + 5 * period   // start year of period: 2005,2010,2015,2020

********************************************************************************
***  SECTION A: Shift-share instrument (Card 2001)
***
***  Three ROW origin groups: AFR_N_ASI_NME, ASI_ESSE, AME_LAT
***  Share  = stock (pop1564) at period start t0 in NUTS2 r / national total at t0
***  Shift  = leave-one-out change in national stock over the 5-year window
***           (national change minus the change in NUTS2 r itself)
***  z_r    = sum_g [ share_{r,g,t0} * (delta_nat_{g} - delta_r_{g}) ]
********************************************************************************

preserve

keep if inlist(countryb, "AFR_N_ASI_NME", "ASI_ESSE", "AME_LAT")

*** Collapse across education: annual region × group stocks
collapse (sum) pop1564, by(country region_2d countryb year period period_t0)

*** Stocks at period start (t0)
tempfile ss_annual
save `ss_annual'

use `ss_annual', clear
keep if year == period_t0
rename pop1564 stock_t0
keep country region_2d countryb period stock_t0
tempfile ss_t0
save `ss_t0'

*** Stocks at period end (t0+4)
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

*** National totals (sum over all NUTS2 of the same country)
bysort country countryb period: egen nat_t0 = total(stock_t0)
bysort country countryb period: egen nat_t1 = total(stock_t1)

*** Shares and leave-one-out shifts
gen share_rg   = stock_t0 / nat_t0          // share of group g in region r at t0
gen delta_nat  = nat_t1   - nat_t0          // national change in group g
gen delta_r    = stock_t1 - stock_t0        // region r change in group g
gen delta_excl = delta_nat - delta_r        // leave-one-out (national excl. r)

*** Shift-share term per group; sum across groups for the instrument
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
*   nat       : native born
*   fb        : all foreign born (with valid countryb)
*   fb_eu     : born in EU (EUR_EU = EU-15 + NMS, see note above)
*   fb_noneu15: born outside EU-15 — approximated as EUR_nonEU + all non-EU groups
*               (NMS portion of EUR_EU is misclassified into fb_eu, not here)
*   fb_adv    : advanced economies outside EU — non-EU Europe (EFTA etc.) +
*               North America + Oceania (NMS excluded due to data limitation)
*   fb_row    : rest of world — N.Africa/ME + E/SE/S Asia + Latin America
gen nat        = (countryb == "NAT")
gen fb         = (countryb != "NAT") & valid_cb
gen fb_eu      = (countryb == "EUR_EU")
gen fb_noneu15 = inlist(countryb, "EUR_nonEU", "AFR_N_ASI_NME", "ASI_ESSE", "AME_N_OCE", "AME_LAT")
gen fb_adv     = inlist(countryb, "EUR_nonEU", "AME_N_OCE")
gen fb_row     = inlist(countryb, "AFR_N_ASI_NME", "ASI_ESSE", "AME_LAT")

*** Tertiary education (ISCED 5-8) and valid education indicator
gen tert       = inlist(educ, "5", "6", "7", "8")
gen educ_valid = educ != "" & !missing(educ)

*** Population by group (all ages and 15-64)
gen pop_tot         = pop     * valid_cb
gen pop_nat         = pop     * nat
gen pop_fb          = pop     * fb
gen pop_fb_eu       = pop     * fb_eu
gen pop_fb_noneu15  = pop     * fb_noneu15
gen pop_fb_adv      = pop     * fb_adv
gen pop_fb_row      = pop     * fb_row

gen pop1564_tot     = pop1564 * valid_cb
gen pop1564_nat     = pop1564 * nat
gen pop1564_fb      = pop1564 * fb
gen pop1564_fb_eu   = pop1564 * fb_eu
gen pop1564_fb_noneu15 = pop1564 * fb_noneu15
gen pop1564_fb_adv  = pop1564 * fb_adv
gen pop1564_fb_row  = pop1564 * fb_row

*** Employment by group (15-64 only; inactive derived below)
gen empl_tot   = empl   * valid_cb
gen empl_nat   = empl   * nat
gen empl_fb    = empl   * fb

gen unempl_tot = unempl * valid_cb
gen unempl_nat = unempl * nat
gen unempl_fb  = unempl * fb

*** Education: numerator (tertiary) and denominator (valid educ), 15-64 only
gen ednum_tot   = pop1564 * valid_cb * tert
gen eddenom_tot = pop1564 * valid_cb * educ_valid

*** Step 1: sum across countryb × educ to annual region-level totals
collapse (sum)  pop_tot pop_nat pop_fb pop_fb_eu pop_fb_noneu15 pop_fb_adv pop_fb_row     ///
                pop1564_tot pop1564_nat pop1564_fb pop1564_fb_eu pop1564_fb_noneu15        ///
                pop1564_fb_adv pop1564_fb_row                                              ///
                empl_tot empl_nat empl_fb                                                  ///
                unempl_tot unempl_nat unempl_fb                                            ///
                ednum_tot eddenom_tot                                                      ///
         (max)  flag_missing_countryb,                                                     ///
    by(country region_2d year period)

*** Inactive 15-64 by group (derived to avoid contamination from non-15-64 ages)
gen inactive_tot = pop1564_tot - empl_tot - unempl_tot
gen inactive_nat = pop1564_nat - empl_nat - unempl_nat
gen inactive_fb  = pop1564_fb  - empl_fb  - unempl_fb

*** Step 2: average across years within each 5-year period
collapse (mean) pop_tot pop_nat pop_fb pop_fb_eu pop_fb_noneu15 pop_fb_adv pop_fb_row     ///
                pop1564_tot pop1564_nat pop1564_fb pop1564_fb_eu pop1564_fb_noneu15        ///
                pop1564_fb_adv pop1564_fb_row                                              ///
                empl_tot empl_nat empl_fb                                                  ///
                unempl_tot unempl_nat unempl_fb                                            ///
                inactive_tot inactive_nat inactive_fb                                      ///
                ednum_tot eddenom_tot                                                      ///
         (max)  flag_missing_countryb,                                                     ///
    by(country region_2d period)

*** Education share (share of 15-64 with tertiary education among those with valid educ)
gen sh_tert = ednum_tot / eddenom_tot

drop ednum_tot eddenom_tot

*** Merge shift-share instrument
merge 1:1 country region_2d period using `ss_final', nogen

*** Restore period start year
gen int period_t0 = 2000 + 5 * period

*** Sort
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

label var pop_tot              "Total population (all ages, 5-yr avg)"
label var pop_nat              "Total population, native born"
label var pop_fb               "Total population, foreign born"
label var pop_fb_eu            "Total population, EU born (EUR_EU; incl. NMS — see note)"
label var pop_fb_noneu15       "Total population, born outside EU-15 approx (excl. NMS in EUR_EU)"
label var pop_fb_adv           "Total population, advanced econ excl. EU (non-EU Eur + N.Am + Oceania)"
label var pop_fb_row           "Total population, rest of world (N.Afr/ME + E/SE/S Asia + Lat.Am)"

label var pop1564_tot          "Population 15-64 (5-yr avg)"
label var pop1564_nat          "Population 15-64, native born"
label var pop1564_fb           "Population 15-64, foreign born"
label var pop1564_fb_eu        "Population 15-64, EU born (incl. NMS)"
label var pop1564_fb_noneu15   "Population 15-64, born outside EU-15 approx"
label var pop1564_fb_adv       "Population 15-64, advanced econ excl. EU"
label var pop1564_fb_row       "Population 15-64, rest of world"

label var empl_tot             "Employed 15-64 (5-yr avg)"
label var empl_nat             "Employed 15-64, native born"
label var empl_fb              "Employed 15-64, foreign born"

label var unempl_tot           "Unemployed 15-64 (5-yr avg)"
label var unempl_nat           "Unemployed 15-64, native born"
label var unempl_fb            "Unemployed 15-64, foreign born"

label var inactive_tot         "Inactive 15-64 = pop1564 - empl - unempl (5-yr avg)"
label var inactive_nat         "Inactive 15-64, native born"
label var inactive_fb          "Inactive 15-64, foreign born"

label var sh_tert              "Share of 15-64 with tertiary educ (ISCED 5-8), valid educ only"

label var ss_instrument        "Card (2001) shift-share: 3 ROW groups (AFR_N_ASI_NME, ASI_ESSE, AME_LAT), leave-one-out within country"

********************************************************************************
***  Save
********************************************************************************

compress
save "${finaldata}/EULFS/eulfs_nuts2_panel_5y.dta", replace
