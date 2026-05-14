
log using "${main}/log/summarize_eurostat_regional_accounts.txt", replace t

* NUTS-3 GDP at current prices (MIO EUR)
clear all
getTimeSeries EUROSTAT NAMA_10R_3GDP/A.MIO_EUR. "" "" 0 0
destring _all, replace
des
list in 1/10

* NUTS-3 GDP at previous-year prices (MIO EUR)
clear all
getTimeSeries EUROSTAT NAMA_10R_3GDP/A.MIO_EUR_PYP. "" "" 0 0
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
