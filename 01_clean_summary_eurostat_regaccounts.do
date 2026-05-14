
log using "${main}/log/summarize_eurostat_regional_accounts.txt", replace t

* GDP at current prices — NUTS-2 (MIO EUR)
clear all
getTimeSeries EUROSTAT NAMA_10R_2GDP/A.MIO_EUR. "" "" 0 0
destring _all, replace
des
list in 1/10

* GVA growth rate — NUTS-2 (% change vs previous year)
clear all
getTimeSeries EUROSTAT NAMA_10R_2GVAGR/A.PCH_PRE. "" "" 0 0
destring _all, replace
des
list in 1/10

* Compensation of employees — NUTS-2 (MIO EUR, all industries)
clear all
getTimeSeries EUROSTAT NAMA_10R_2COE/A.MIO_EUR.TOTAL. "" "" 0 0
destring _all, replace
des
list in 1/10

* Net household disposable income — NUTS-2 (MIO EUR, balance B6N)
clear all
getTimeSeries EUROSTAT NAMA_10R_2HHINC/A.MIO_EUR.BAL.B6N. "" "" 0 0
destring _all, replace
des
list in 1/10

log close
