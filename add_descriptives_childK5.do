clear all
set maxvar 30000
set more off

global output_directory "my_directory"
global input_directory "my_directory"

/*******************************************************************************
PROGRAM NAME: add_descriptives_childK5.do
AUTHOR: Xia Zheng
PURPOSE: create two descriptive statistics tables for chapters 1 and 2
NOTES: XZ created on 4/8/2023
*******************************************************************************/

********Table 1 neighborhood characteristics by treatment*********
use "${output_directory}v01_acs.dta", clear    
keep tt_id tt_year tt_educ1 tt_educ4 tt_fhfam tt_povtr tt_unemp
keep if tt_year == 2013    // second grade
gen merge_id = tt_id
sort merge_id
drop tt_id tt_year
tempfile using
save `using'

use "${output_directory}childK5_procd.dta", clear
gen merge_id = nctid_sp2    // treatment at second grade 
sort merge_id
merge m:1 merge_id using `using', keep(1 3) nogenerate
drop merge_id

keep ncid nctid_sp2 nctdisad_sp2_ter tt_educ1 tt_educ4 tt_fhfam tt_povtr tt_unemp ///
ngender nbirthy nrace ndisab nlang nspedu nfnumhm nfptype nfpage nfpmarried ///
nfhses nschtype nschenroll nschreg nschloc nsoc_sp3 nexprobbehavs_sp3

keep if !missing(ngender, nbirthy, nrace, ndisab, nlang, nspedu, nfnumhm, nfptype, nfpage, nfpmarried, ///
nfhses, nschtype, nschenroll, nschreg, nschloc, nctdisad_sp2_ter, nsoc_sp3, nexprobbehavs_sp3)

eststo treat: estpost sum tt_educ1 tt_educ4 tt_fhfam tt_povtr tt_unemp if nctdisad_sp2_ter == 1, listwise
eststo control: estpost sum tt_educ1 tt_educ4 tt_fhfam tt_povtr tt_unemp if nctdisad_sp2_ter == 0, listwise
esttab treat control using "${output_directory}ndisad_comparison.rtf", main(mean) b(3) label ///
title("Neighborhood characteristics by treatment groups") mtitle("Treated" "Control") ///
nostar replace
eststo clear

********Table 2 covariates by treatment chp1*********
use "${output_directory}childK5_procd.dta", clear
keep nctdisad_sp2_ter ncog_sp5 ngender nbirthy nrace ndisab nlang nspedu nfnumhm nfptype nfpage nfpmarried nfhses nschtype nschenroll nschreg nschloc
keep if !missing(nctdisad_sp2_ter, ncog_sp5, ngender, nbirthy, nrace, ndisab, nlang, nspedu, nfnumhm, nfptype, nfpage, nfpmarried, nfhses, nschtype, nschenroll, nschreg, nschloc)

recode nlang (3 = 0) (1 = 0) (2 = 1)
label define nlang_lbl 0 "non-english" 1 "english", replace
label values nlang nlang_lbl

recode nfptype (3 = 0) (4 = 0) (2 = 0)
label define nfptype_lbl 0 "missing at least one bio/adop parent" 1 "two bio/adop parents" , replace
label values nfptype nfptype_lbl

recode nschloc (2 = 1) (3 = 0) (4 = 0)
label define nschloc_lbl 0 "town/rural" 1 "city/suburb", replace
label values nschloc nschloc_lbl

asdoc sum ncog_sp5 nbirthy nfnumhm nfpage nfhses if nctdisad_sp2_ter == 1, save(descriptives_chp1)
asdoc sum ncog_sp5 nbirthy nfnumhm nfpage nfhses if nctdisad_sp2_ter == 0
asdoc tab1 ngender ndisab nspedu nlang nfptype nfpmarried nschtype nschloc nrace nschenroll nschreg if nctdisad_sp2_ter == 1
asdoc tab1 ngender ndisab nspedu nlang nfptype nfpmarried nschtype nschloc nrace nschenroll nschreg if nctdisad_sp2_ter == 0

/*  
eststo treat: estpost sum ncog_sp5 nctdisad_sp2_ter ngender nbirthy nrace ndisab nlang nspedu nfnumhm nfptype nfpage nfpmarried nfhses nschtype nschenroll nschreg nschloc if nctdisad_sp2_ter == 1, listwise
eststo control: estpost sum ncog_sp5 nctdisad_sp2_ter ngender nbirthy nrace ndisab nlang nspedu nfnumhm nfptype nfpage nfpmarried nfhses nschtype nschenroll nschreg nschloc if nctdisad_sp2_ter == 0, listwise
esttab treat control using "${output_directory}covariates_descriptives_1.rtf", main(mean) b(3) label ///
title("Summary statistics of covariates by treatment groups") mtitle("Treated" "Control") ///
nostar replace
eststo clear */

********Table 2 covariates by treatment chp2*********
use "${output_directory}childK5_procd.dta", clear
keep nctdisad_sp2_ter nsoc_sp3 nexprobbehavs_sp3 ngender nbirthy nrace ndisab nlang nspedu nfnumhm nfptype nfpage nfpmarried nfhses nschtype nschenroll nschreg nschloc
keep if !missing(nctdisad_sp2_ter, nsoc_sp3, nexprobbehavs_sp3, ngender, nbirthy, nrace, ndisab, nlang, nspedu, nfnumhm, nfptype, nfpage, nfpmarried, nfhses, nschtype, nschenroll, nschreg, nschloc)

recode nlang (3 = 0) (1 = 0) (2 = 1)
label define nlang_lbl 0 "non-english" 1 "english", replace
label values nlang nlang_lbl

recode nfptype (3 = 0) (4 = 0) (2 = 0)
label define nfptype_lbl 0 "missing at least one bio/adop parent" 1 "two bio/adop parents" , replace
label values nfptype nfptype_lbl

recode nschloc (2 = 1) (3 = 0) (4 = 0)
label define nschloc_lbl 0 "town/rural" 1 "city/suburb", replace
label values nschloc nschloc_lbl

asdoc sum nsoc_sp3 nexprobbehavs_sp3 nbirthy nfnumhm nfpage nfhses if nctdisad_sp2_ter == 1, save(descriptives_chp2)
asdoc sum nsoc_sp3 nexprobbehavs_sp3 nbirthy nfnumhm nfpage nfhses if nctdisad_sp2_ter == 0
asdoc tab1 ngender nrace ndisab nlang nspedu nfptype nfpmarried nschtype nschenroll nschreg nschloc if nctdisad_sp2_ter == 1
asdoc tab1 ngender nrace ndisab nlang nspedu nfptype nfpmarried nschtype nschenroll nschreg nschloc if nctdisad_sp2_ter == 0

/*
eststo treat: estpost sum nctdisad_sp2_ter nsoc_sp3 nexprobbehavs_sp3 ngender nbirthy nrace ndisab nlang nspedu nfnumhm nfptype nfpage nfpmarried nfhses nschtype nschenroll nschreg nschloc if nctdisad_sp2_ter == 1, listwise
eststo control: estpost sum nctdisad_sp2_ter nsoc_sp3 nexprobbehavs_sp3 ngender nbirthy nrace ndisab nlang nspedu nfnumhm nfptype nfpage nfpmarried nfhses nschtype nschenroll nschreg nschloc if nctdisad_sp2_ter == 0, listwise
esttab treat control using "${output_directory}covariates_descriptives_2.rtf", main(mean) b(3) label ///
title("Summary statistics of covariates by treatment groups") mtitle("Treated" "Control") ///
nostar replace
eststo clear
*/

