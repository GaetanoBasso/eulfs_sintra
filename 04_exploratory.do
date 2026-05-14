
********************************************************************************
*
*   04_exploratory.do
*   Exploratory analysis: shift-share first stage
*
*   Regression:
*     Δ pop_fb_row(r,t) = β * ss_instrument(r,t) + α_r + α_t + ε(r,t)
*
*   where:
*     Δ pop_fb_row(r,t) = change in stock of ROW foreign-born (all ages)
*                         between 5-year period t-1 and t
*     ss_instrument(r,t) = Card (2001) shift-share: AFR_N_ASI_NME + ASI_ESSE
*                          + AME_LAT groups, leave-one-out across all regions
*     α_r = region fixed effect
*     α_t = period fixed effect
*     weight = total population of region r in 2005-2009 (period 1)
*
*   Standard errors clustered at the region level.
*
*   Input: ${finaldata}/working_nuts2_panel_5y.dta
*
********************************************************************************

use "${finaldata}/working_nuts2_panel_5y.dta", clear

*** Numeric region ID for xtset
encode region_2d, gen(region_id)
xtset region_id period

*** Weight: 2005-2009 (period 1) total population, constant across periods
bysort region_id (period): gen pop_weight = pop_tot[1]
label var pop_weight "Weight: total population 2005-2009 (period 1, all ages)"

*** Change in stock of ROW foreign-born (period-to-period difference)
gen d_pop_fb_row = pop_fb_row - L.pop_fb_row
label var d_pop_fb_row "Δ ROW foreign-born stock (all ages, period-on-period)"

*** Share of ROW foreign-born in total population (for description)
gen sh_fb_row     = pop_fb_row / pop_tot
gen d_sh_fb_row   = sh_fb_row  - L.sh_fb_row
label var sh_fb_row   "Share of ROW foreign-born in total population"
label var d_sh_fb_row "Δ share of ROW foreign-born"

********************************************************************************
***  DESCRIPTIVE STATISTICS
********************************************************************************

tabstat pop_fb_row d_pop_fb_row ss_instrument pop_tot ///
        [aw = pop_weight], ///
    stat(n mean sd p10 p50 p90) col(stat) format(%12.2f)

*** Cross-period mean by country
table country period [aw = pop_weight], ///
    stat(mean pop_fb_row ss_instrument)

********************************************************************************
***  MAIN REGRESSION
***  Δ pop_fb_row on ss_instrument, region FE + period FE, pop-weighted
********************************************************************************

* Drop period 1: no lagged value → no first difference
regress d_pop_fb_row ss_instrument i.region_id i.period ///
    [pw = pop_weight] if !missing(d_pop_fb_row), ///
    vce(cluster region_id)

est store fe_fd

********************************************************************************
***  ROBUSTNESS: normalise by 2005 population (scale-free coefficient)
********************************************************************************

gen d_pop_fb_row_s = d_pop_fb_row / pop_weight * 1000   // per 1,000 inhabitants
gen ss_instr_s     = ss_instrument / pop_weight * 1000
label var d_pop_fb_row_s "Δ ROW foreign-born per 1,000 (2005) inhabitants"
label var ss_instr_s     "Shift-share per 1,000 (2005) inhabitants"

regress d_pop_fb_row_s ss_instr_s i.region_id i.period ///
    [pw = pop_weight] if !missing(d_pop_fb_row_s), ///
    vce(cluster region_id)

est store fe_fd_s

********************************************************************************
***  DISPLAY RESULTS
********************************************************************************

estout fe_fd fe_fd_s, ///
    cells(b(star fmt(3)) se(par fmt(3))) ///
    stats(N r2, fmt(%9.0f %9.3f) labels("Observations" "R-squared")) ///
    keep(ss_instrument ss_instr_s) ///
    varlabels(ss_instrument "Shift-share instrument" ///
              ss_instr_s    "Shift-share (per 1,000 inh.)") ///
    mlabels("Δ ROW f.-b." "Δ ROW f.-b. per 1,000") ///
    note("Region FE, period FE. Clustered SE at region level. " ///
         "Weighted by 2005-2009 total population.")

********************************************************************************
***  BINNED SCATTER: partial correlation after absorbing FE and weights
***  (residualise both variables on region FE + period FE)
********************************************************************************

* Residualise on FE using weighted regression absorbing dummies
quietly regress d_pop_fb_row i.region_id i.period ///
    [pw = pop_weight] if !missing(d_pop_fb_row), noconstant
predict r_dep if !missing(d_pop_fb_row), resid

quietly regress ss_instrument i.region_id i.period ///
    [pw = pop_weight] if !missing(d_pop_fb_row), noconstant
predict r_ins if !missing(d_pop_fb_row), resid

twoway (scatter r_dep r_ins [w = pop_weight], ///
            mcolor(navy%40) msymbol(circle) msize(small)) ///
       (lfit   r_dep r_ins [w = pop_weight], ///
            lcolor(cranberry) lwidth(medthick)), ///
    xtitle("Shift-share instrument (residualised)") ///
    ytitle("Δ ROW foreign-born stock (residualised)") ///
    title("Shift-share vs change in ROW foreign-born stock") ///
    subtitle("Partial correlation: region FE + period FE absorbed") ///
    legend(off) ///
    name(ss_scatter, replace)

graph export "${vizdata}/ss_first_stage_scatter.png", replace
