********************************************************************************
*
*	Master file for Eurostat/EU-LFS data for ECB-Sintra 2026 project
*
********************************************************************************
clear all
set more off
cap adopath - SITE 

*** Setup
if c(username) == "m029601" {
	if `"`c(os)'"' == "Windows" 		global   stem   `"//osiride-fs/m029601/private"'
	if `"`c(os)'"' == "Unix" 		global   stem   `"/home/user/m029601/private"'
}
if c(username) == "" global main "~/Dropbox/ECB_project_2026/Empirical Analysis/"
global main "${stem}/ECBsintra2026"

*** Paths
global data 			"${main}/01_Data"
global rawdata 			"${data}/01_raw"
global cleaneddata 		"${data}/02_cleaned"
global finaldata 		"${data}/03_final"
global vizdata 			"${data}/04_viz"
global prog			"${main}/02_Code"
*global log 			"${main}/"
global graphs 			"${main}/03_Viz"

global EULFSsource		"/home/group/main/rdc/private/EULFS/dati"
global EULFS2024		"${EULFSsource}/Yearly_Files/csv"
global EULFS2020		"${EULFSsource}/old_data_strucure_2020/Yearly_Files/stata"
global temp			"${data}/temp"

*** Run general programs 
do "${prog}/global_parameters.do"

*** Run cleaning programs 
do "${prog}/01_clean_summary_EULFS.do"
do "${prog}/01_clean_eurostat_pop.do"
do "${prog}/01_clean_cells_EULFS.do"
do "${prog}/01_clean_IMPIC.do"

*** Run analysis programs 

