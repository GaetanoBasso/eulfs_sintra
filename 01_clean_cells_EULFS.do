
*** From 2021 files
local names_files: dir "${EULFS2024}" files "*" // Local: list - all files in a folder
di "File names in folder ${EULFS2024} are: " `names_files'
 
foreach lvl_names_files of local names_files {
	import delimited using ${EULFS2024}/`lvl_names_files', clear varnames(1)
	//import delimited using ${EULFS2024}/DE2023_y.csv, clear varnames(1)
	cap renvars *, lower
	tostring countryb, replace
	replace countryb="" if countryb=="."
	replace countryb=trim(countryb)
	replace countryb="EU28" if (countryb=="EU15"|countryb=="NMS10"|countryb=="NMS3"|countryb=="NMS13")&year<2020
	replace countryb="EUR_NEU28" if (countryb=="EFTA"|countryb=="EUR_NEU28_NEFTA"|countryb=="NEU15")&year<2020
	replace countryb="EUR_NEU27_2020" if (countryb=="EFTA"|countryb=="EUR_NEU27_2020_NEFTA")&year>=2020
	replace countryb="EUR_EU" if countryb=="EU27_2020"|countryb=="EU28"
	replace countryb="EUR_nonEU" if countryb=="EUR_NEU28"|countryb=="EUR_NEU27_2020"
	replace countryb="AFR_N_ASI_NME" if countryb=="AFR_N"|countryb=="ASI_NME"
	replace countryb="ASI_ESSE" if countryb=="ASI_E"|countryb=="ASI_S_E"|countryb=="ASI_SSE"
	replace countryb="AME_N_OCE" if countryb=="AME_N"|countryb=="OCE"
	replace countryb="AME_LAT" if countryb=="AME_C_CRB"|countryb=="AME_S"
	destring year, replace
	*in case we need more details (to be modified anyway): gen educ=1*(hatlev1d<=2)+2*(hatlev1d>=3&hatlev1d<=4)+3*(hatlev1d>=5&hatlev1d<=8)
	*replace educ = . if hatlev1d==.|hatlev1d==9
	tostring hatlev1d, replace
	replace hatlev1d="" if hatlev1d=="."
	gen educ=hatlev1d
	replace educ="" if hatlev1d=="9"|hatlev1d==""
	gen age_4bins=1 if (age_gr=="Y0-4"|age_gr=="Y5-9"|age_gr=="Y10-14")
	replace age_4bins= 3 if (age_gr=="Y65-69"|age_gr=="Y70-74")
	replace age_4bins= 4 if (age_gr=="Y75-79"|age_gr=="Y80-84"|age_gr=="Y85-89"|age_gr=="Y90-94"|age_gr=="Y95-99"|age_gr=="Y_GE100")
	replace age_4bins=2 if age_4bins==.&age_gr!=""
	gen pop=1 if countryb!=""&countryb!="NO ANSWER"&countryb!="999"
	gen pop1564=1 if age_4bins==2&countryb!=""&countryb!="NO ANSWER"&countryb!="999"
	gen empl=1 if ilostat==1&age_4bins==2&countryb!=""&countryb!="NO ANSWER"&countryb!="999"
	gen unempl=1 if ilostat==2&age_4bins==2&countryb!=""&countryb!="NO ANSWER"&countryb!="999"
	gen inactive=1 if ((ilostat==3&age_4bins==2)|(age_4bins!=2))&countryb!=""&countryb!="NO ANSWER"&countryb!="999"
	collapse (sum) pop1564 pop empl unempl inactive [pw=coeffy], by(year country countryb educ region_2d) //age (as a cell)
	* in case we have a num variable (to be modified accordingly): label define ee 1 "Lower Secondary" 2 "Upper Secondary" 3 "Tertiary"
	*label values educ ee
	*label define aa 1 "<15" 2 "15-64" 3 "65-74" 4 "75+"
	*label values age aa
	qui tab countryb
	scalar ncountry=`r(r)' 
	gen flag_missing_countryb=(ncountry<12)
	gen fborn=(countryb!="NAT")
	cap compress
	cap saveold ${temp}/`lvl_names_files', replace
}

clear all
foreach lvl_names_files of local names_files {
	append using ${temp}/`lvl_names_files'
}
drop if year<=2003
sort country year
tab country year, m
order country year educ countryb fborn flag pop pop1564 empl unempl inactive //age 
tab flag, m
drop flag
la var country "Country"
la var countryb "Country group of birth"
la var educ "Highest ed. lev. attained (LowSec,UppSec,Ter)"
la var fborn "1=(Country birth!=Country)"
*la var age_4bins "<15,15-64,65-74,75+"
la var pop "Population in the cell"
la var pop1564 "Population 15-64 in the cell"
la var empl "Employed 15-64 in the cell"
la var unempl "Unemployed 15-64 in the cell"
la var inactive "Inactive 15-64 in the cell"
compress
save ${cleaneddata}/EULFS/eulfs_byorigin_byage_byedu_byregion_2004_2024.dta, replace
save ${cleaneddata}/EULFS/eulfs_byorigin_byedu_byregion_2004_2024.dta, replace

********************************************************************
***	Describe dataset 
********************************************************************
log using ${vizdata}/describe_eulfs_cell_dataset.txt, t replace
describe
tab country, m
tab year, m
tab educ, m
tab age, m
tab countryb, m
tab region_2d, m
log close
********************************************************************
***	Cleaning temp files
********************************************************************
clear all
cd ${temp}
foreach lvl_names_files of local names_files {
	!rm `lvl_names_files'
}


COSTRUIRE DATASET CON OUTCOME POPULATION AND EMPLOYMENT (WORKING AGE O MENO) AND IMMIGRATI NON EU13 E UNO CON CELLE DI IMMIGRATI PER REGIONE E UNO CON CELLE PER REGIONE ESCLUDENDO NAM-OCE E EUR_NONEU. FARE TUTTO IN MEDIE DI 5 ANNI. POI SCARICARE REGIONAL ACCOUNTS DA EUROSTAT E FARE MEDIE DI 5 ANNI
