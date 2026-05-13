
log using ${main}/log/summarize_eurostat_regional_accounts.txt, replace t

* GDP at current values in euro
clear all
getTimeSeries EUROSTAT NAMA_10R_2GDP/A.MIO_EUR. "" "" 0 0
destring _all, replace
des
list in 1/10

* GDP at previous-year values in euro
clear all
getTimeSeries EUROSTAT NAMA_10R_2GDP/A.MIO_EUR. "" "" 0 0
destring _all, replace
des
list in 1/10

* Compensation of employees
clear all
getTimeSeries EUROSTAT NAMA_10R_2COE/A.MIO_EUR.TOTAL. "" "" 0 0
destring _all, replace
des
list in 1/10

* Household disposable income
clear all
getTimeSeries EUROSTAT NAMA_10R_2HHINC/A.MIO_EUR.BAL.B6N. "" "" 0 0
destring _all, replace
des
list in 1/10

log close

