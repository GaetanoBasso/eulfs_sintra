
********************************************************************************
*
*   00_nuts2_crosswalk.do
*   NUTS-2 code crosswalk: older vintages → current codes (NUTS 2016 / 2021)
*
*   Purpose:
*     EU-LFS encodes region_2d using the NUTS classification current at survey
*     time.  Eurostat regional accounts use a later vintage.  This dofile
*     (a) saves a crosswalk dataset and (b) applies 1:1 recodes to the EU-LFS
*     NUTS-2 panel so that region codes align with the Eurostat data.
*
*   IMPORTANT: mappings marked [VERIFY] should be cross-checked against the
*   official Eurostat NUTS correspondence tables (CSV/XLSX downloads at
*   https://ec.europa.eu/eurostat/web/nuts/correspondence-tables).
*   The present entries are based on the Eurostat NUTS history page and the
*   Wikipedia article on NUTS statistical regions of France.
*
*   Changes covered and their NUTS revision:
*
*     France   NUTS 2013 → 2016
*       Complete code restructuring following the 2016 administrative reform.
*       All 25 pre-reform codes (FR21–FR94, excl. FR10) map 1:1 to new codes.
*       FR10 (Île-de-France) is unchanged.
*       Source: EC Decision 2016/2066 and the Wikipedia article on NUTS
*       statistical regions of France.
*
*     Greece   NUTS 2006 → 2010
*       GR prefix renamed EL (ISO 3166-1 alpha-2 code for Greece).
*       All 13 NUTS-2 boundaries unchanged; purely a prefix change.
*
*     Poland   NUTS 2013 → 2016  [VERIFY]
*       Eastern regions renumbered: PL11→PL71, PL3x→PL8x.
*       PL12 (Mazowieckie) split into PL91 (Warszawski stołeczny) and
*       PL92 (Mazowiecki regionalny) to separate the Warsaw metro area.
*       Regions PL21, PL22, PL41–PL43, PL51, PL52, PL61–PL63 are unchanged.
*
*     Ireland  NUTS 2013 → 2016  [VERIFY; boundary change]
*       IE01 → IE04 (Northern & Western; approximate match to old Border,
*         Midland & Western).
*       IE02 → IE05 + IE06: Southern & Eastern was split into Southern and
*         Eastern & Midland.  flag_split = 1 for this case.
*
*     Hungary  NUTS 2016 → 2021
*       HU10 (Közép-Magyarország / Central Hungary) split into HU11 (Budapest)
*       and HU12 (Pest).  flag_split = 1.
*       All other Hungarian NUTS-2 codes (HU21–HU33) unchanged.
*
*     Germany  NUTS 2010 → 2013, Saxony  [VERIFY]
*       The three Saxon Direktionsbezirk-based regions were renumbered when
*       the Direktionsbezirke were abolished in 2012:
*         DED1 (Chemnitz) → DED4
*         DED2 (Dresden)  → DED5
*         DED3 (Leipzig)  → DED2
*       WARNING: DED2 has different meanings before and after this change.
*       The recode is applied only to periods 1–2 (2005–2014) on the assumption
*       that the LFS for Germany adopted NUTS 2013 codes no earlier than 2015.
*       Verify this assumption before use.
*
*   Mapping types:
*     1:1  = one-to-one code change; boundaries unchanged (simple rename)
*     1:M  = one old code maps to multiple new codes (region was split)
*            EU-LFS observations with flag_split = 1 cannot be matched to a
*            single Eurostat NUTS-2 region without aggregating the Eurostat side.
*
*   Outputs:
*     ${cleaneddata}/nuts2_crosswalk.dta   (crosswalk lookup table)
*     ${finaldata}/EULFS/eulfs_nuts2_panel_5y.dta   (updated in place)
*
********************************************************************************

* ============================================================================ *
*  PART 1: Build and save the crosswalk lookup table                           *
* ============================================================================ *

clear

* Columns:
*   region_2d_old  NUTS-2 code as it appears in EU-LFS
*   region_2d_new  Current NUTS-2 code (NUTS 2016 or 2021)
*   nuts_from      NUTS revision of the old code
*   nuts_to        NUTS revision of the new code
*   map_type       "1:1" or "1:M"
*   flag_split     1 when the old region was split (1:M); 0 otherwise
*
* Only changed codes are listed.  Codes absent from this table are unchanged.

input str4(region_2d_old region_2d_new nuts_from nuts_to) str3 map_type byte flag_split

"FR21" "FRF2" "2013" "2016" "1:1" 0
"FR22" "FRE2" "2013" "2016" "1:1" 0
"FR23" "FRD2" "2013" "2016" "1:1" 0
"FR24" "FRB0" "2013" "2016" "1:1" 0
"FR25" "FRD1" "2013" "2016" "1:1" 0
"FR26" "FRC1" "2013" "2016" "1:1" 0
"FR30" "FRE1" "2013" "2016" "1:1" 0
"FR41" "FRF3" "2013" "2016" "1:1" 0
"FR42" "FRF1" "2013" "2016" "1:1" 0
"FR43" "FRC2" "2013" "2016" "1:1" 0
"FR51" "FRG0" "2013" "2016" "1:1" 0
"FR52" "FRH0" "2013" "2016" "1:1" 0
"FR53" "FRI3" "2013" "2016" "1:1" 0
"FR61" "FRI1" "2013" "2016" "1:1" 0
"FR62" "FRJ2" "2013" "2016" "1:1" 0
"FR63" "FRI2" "2013" "2016" "1:1" 0
"FR71" "FRK2" "2013" "2016" "1:1" 0
"FR72" "FRK1" "2013" "2016" "1:1" 0
"FR81" "FRJ1" "2013" "2016" "1:1" 0
"FR82" "FRL0" "2013" "2016" "1:1" 0
"FR83" "FRM0" "2013" "2016" "1:1" 0
"FR91" "FRY1" "2013" "2016" "1:1" 0
"FR92" "FRY2" "2013" "2016" "1:1" 0
"FR93" "FRY3" "2013" "2016" "1:1" 0
"FR94" "FRY4" "2013" "2016" "1:1" 0
"GR11" "EL11" "2006" "2010" "1:1" 0
"GR12" "EL12" "2006" "2010" "1:1" 0
"GR13" "EL13" "2006" "2010" "1:1" 0
"GR14" "EL14" "2006" "2010" "1:1" 0
"GR21" "EL21" "2006" "2010" "1:1" 0
"GR22" "EL22" "2006" "2010" "1:1" 0
"GR23" "EL23" "2006" "2010" "1:1" 0
"GR24" "EL24" "2006" "2010" "1:1" 0
"GR25" "EL25" "2006" "2010" "1:1" 0
"GR30" "EL30" "2006" "2010" "1:1" 0
"GR41" "EL41" "2006" "2010" "1:1" 0
"GR42" "EL42" "2006" "2010" "1:1" 0
"GR43" "EL43" "2006" "2010" "1:1" 0
"PL11" "PL71" "2013" "2016" "1:1" 0
"PL12" "PL91" "2013" "2016" "1:M" 1
"PL12" "PL92" "2013" "2016" "1:M" 1
"PL31" "PL81" "2013" "2016" "1:1" 0
"PL32" "PL82" "2013" "2016" "1:1" 0
"PL33" "PL84" "2013" "2016" "1:1" 0
"PL34" "PL85" "2013" "2016" "1:1" 0
"IE01" "IE04" "2013" "2016" "1:1" 0
"IE02" "IE05" "2013" "2016" "1:M" 1
"IE02" "IE06" "2013" "2016" "1:M" 1
"HU10" "HU11" "2016" "2021" "1:M" 1
"HU10" "HU12" "2016" "2021" "1:M" 1
"DED1" "DED4" "2010" "2013" "1:1" 0
"DED2" "DED5" "2010" "2013" "1:1" 0
"DED3" "DED2" "2010" "2013" "1:1" 0

end

label var region_2d_old "NUTS-2 code (older vintage, as in EU-LFS)"
label var region_2d_new "NUTS-2 code (current vintage, as in Eurostat regional accounts)"
label var nuts_from     "NUTS revision of old code"
label var nuts_to       "NUTS revision of new code"
label var map_type      "1:1 = simple rename; 1:M = split (flag_split=1)"
label var flag_split    "=1 if old region was split into multiple new regions"

compress
save "${cleaneddata}/nuts2_crosswalk.dta", replace

* ============================================================================ *
*  PART 2: Apply crosswalk to EU-LFS NUTS-2 panel (1:1 recodes only)          *
* ============================================================================ *

use "${finaldata}/EULFS/eulfs_nuts2_panel_5y.dta", clear

gen region_2d_orig = region_2d
label var region_2d_orig "Original EU-LFS NUTS-2 code (pre-crosswalk)"

* --- France: NUTS 2013 → 2016 -----------------------------------------------
* FR10 (Île-de-France) is unchanged.
replace region_2d = "FRF2" if region_2d == "FR21"
replace region_2d = "FRE2" if region_2d == "FR22"
replace region_2d = "FRD2" if region_2d == "FR23"
replace region_2d = "FRB0" if region_2d == "FR24"
replace region_2d = "FRD1" if region_2d == "FR25"
replace region_2d = "FRC1" if region_2d == "FR26"
replace region_2d = "FRE1" if region_2d == "FR30"
replace region_2d = "FRF3" if region_2d == "FR41"
replace region_2d = "FRF1" if region_2d == "FR42"
replace region_2d = "FRC2" if region_2d == "FR43"
replace region_2d = "FRG0" if region_2d == "FR51"
replace region_2d = "FRH0" if region_2d == "FR52"
replace region_2d = "FRI3" if region_2d == "FR53"
replace region_2d = "FRI1" if region_2d == "FR61"
replace region_2d = "FRJ2" if region_2d == "FR62"
replace region_2d = "FRI2" if region_2d == "FR63"
replace region_2d = "FRK2" if region_2d == "FR71"
replace region_2d = "FRK1" if region_2d == "FR72"
replace region_2d = "FRJ1" if region_2d == "FR81"
replace region_2d = "FRL0" if region_2d == "FR82"
replace region_2d = "FRM0" if region_2d == "FR83"
replace region_2d = "FRY1" if region_2d == "FR91"
replace region_2d = "FRY2" if region_2d == "FR92"
replace region_2d = "FRY3" if region_2d == "FR93"
replace region_2d = "FRY4" if region_2d == "FR94"

* --- Greece: NUTS 2006 → 2010 (GR → EL prefix) -----------------------------
replace region_2d = "EL" + substr(region_2d, 3, .) if substr(region_2d, 1, 2) == "GR"

* --- Poland: NUTS 2013 → 2016 (1:1 cases; PL12 split handled below) --------
replace region_2d = "PL71" if region_2d == "PL11"
replace region_2d = "PL81" if region_2d == "PL31"
replace region_2d = "PL82" if region_2d == "PL32"
replace region_2d = "PL84" if region_2d == "PL33"
replace region_2d = "PL85" if region_2d == "PL34"

* --- Ireland: NUTS 2013 → 2016 (1:1 case; IE02 split handled below) --------
replace region_2d = "IE04" if region_2d == "IE01"

* --- Germany Saxony: NUTS 2010 → 2013 [VERIFY] ------------------------------
* Applied only to periods 1–2 (2005–2014) to avoid misrecoding the new DED2
* (Leipzig) that appears in later periods once Germany adopted NUTS 2013 codes.
* The assumption that NUTS 2013 was adopted from period 3 onward should be
* verified against the EU-LFS country-specific documentation.
replace region_2d = "DED4" if region_2d == "DED1" & period <= 2
replace region_2d = "DED5" if region_2d == "DED2" & period <= 2
replace region_2d = "DED2" if region_2d == "DED3" & period <= 2

* --- Flag split cases (cannot map to a single new NUTS-2 region) ------------
gen byte flag_nuts_split = 0
replace flag_nuts_split = 1 if region_2d_orig == "PL12"  // → PL91 + PL92
replace flag_nuts_split = 1 if region_2d_orig == "IE02"  // → IE05 + IE06
replace flag_nuts_split = 1 if region_2d_orig == "HU10"  // → HU11 + HU12
label var flag_nuts_split "=1 if region split in later NUTS revision (no 1:1 Eurostat match)"

label var region_2d "NUTS-2 code (updated to current vintage where applicable)"

compress
save "${finaldata}/EULFS/eulfs_nuts2_panel_5y.dta", replace

* ============================================================================ *
*  PART 3: Notes on handling split cases in 03_merge_panels.do                *
* ============================================================================ *

* For regions where the EU-LFS old code was split into multiple current NUTS-2
* codes in the Eurostat regional accounts, two strategies are available:
*
* Strategy A — Aggregate Eurostat to old boundaries (preferred for time series):
*   In the Eurostat data, sum GDP, COE, HHINC etc. across the pair of new
*   regions, and assign the result the old region code before merging.
*   Example for PL12: aggregate PL91 + PL92 → PL12.
*   Example for HU10: aggregate HU11 + HU12 → HU10.
*   Example for IE02: aggregate IE05 + IE06 → IE02.
*
* Strategy B — Drop split observations:
*   Drop LFS observations with flag_nuts_split = 1 before merging.
*   Loses 3 region × T observation groups but avoids any aggregation choice.
*
* Implement whichever strategy is chosen at the top of 03_merge_panels.do,
* before the merge step.

di as txt _n "Crosswalk applied to eulfs_nuts2_panel_5y.dta."
di as txt "Split regions (flag_nuts_split=1): PL12, IE02, HU10."
di as txt "See Part 3 notes for handling these in 03_merge_panels.do."
