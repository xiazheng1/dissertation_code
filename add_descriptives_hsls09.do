clear all
set maxvar 30000
set more off

global output_directory "U:\Xia.Zheng.P00148\data\"

/*******************************************************************************
PROGRAM NAME: add_descriptives_hsls09.do
AUTHOR: Xia Zheng
PURPOSE: create two descriptive tables for chapter 3
NOTES: XZ created on 5/13/2024
*******************************************************************************/

********Table 1 neighborhood characteristics by treatment*********

use "${output_directory}v01_acs.dta", clear    
keep tt_id tt_year tt_educ1 tt_educ4 tt_fhfam tt_povtr tt_unemp
keep if tt_year == 2012    // second grade
gen merge_id = tt_id
sort merge_id
drop tt_id tt_year
tempfile using
save `using'

use "${output_directory}hsls_BYF2_procd.dta", clear
gen merge_id = nctid_2012    // treatment at second grade 
sort merge_id
merge m:1 merge_id using `using', keep(1 3) nogenerate
drop merge_id

keep nctid_2012 nctdisad_2012_ter tt_educ1 tt_educ4 tt_fhfam tt_povtr tt_unemp ///
ngender nrace nbirthy nlang nexpct ndisab nptype nnumhm nses npage nschtype nschloc nschreg nschrp nevercol

keep if !missing(nctdisad_2012_ter, tt_educ1, tt_educ4, tt_fhfam, tt_povtr, tt_unemp, ///
ngender, nrace, nbirthy, nlang, nexpct, ndisab, nptype, nnumhm, nses, npage, nschtype, nschloc, nschreg, nschrp, nevercol)

eststo treat: estpost sum tt_educ1 tt_educ4 tt_fhfam tt_povtr tt_unemp if nctdisad_2012_ter == 1, listwise
eststo control: estpost sum tt_educ1 tt_educ4 tt_fhfam tt_povtr tt_unemp if nctdisad_2012_ter == 0, listwise
esttab treat control using "${output_directory}ndisad_comparison.rtf", main(mean) b(3) label ///
title("Neighborhood characteristics by treatment groups") mtitle("Treated" "Control") ///
nostar replace
eststo clear

********Table 2 covariates by treatment chp3*********
use "${output_directory}hsls_BYF2_procd.dta", clear
keep nctdisad_2012_ter nevercol ngender nrace nbirthy nlang nexpct ndisab nptype nnumhm nses npage nschtype nschloc nschreg nschrp
keep if !missing(nctdisad_2012_ter, nevercol, ngender, nrace, nbirthy, nlang, nexpct, ndisab, nptype, nnumhm, nses, npage, nschtype, nschloc, nschreg, nschrp)

recode nexpct (1/5 = 0) (6/7=1) (8/10=2)
label define nexpct_lbl 0 "below bachelor's" 1 "bachelor's" 2 "master's and above", replace
label values nexpct nexpct_lbl

asdoc sum nbirthy nnumhm npage nses if nctdisad_2012_ter == 1, save(descriptives_chp3)
asdoc sum nbirthy nnumhm npage nses if nctdisad_2012_ter == 0
asdoc tab1 nevercol ngender nrace nlang nexpct ndisab nptype nschtype nschloc nschreg nschrp if nctdisad_2012_ter == 1
asdoc tab1 nevercol ngender nrace nlang nexpct ndisab nptype nschtype nschloc nschreg nschrp if nctdisad_2012_ter == 0

/*
eststo treat: estpost sum nctdisad_2012_ter nevercol ngender nrace nbirthy nlang nexpct ndisab nptype nnumhm nses npage nschtyp nschloc nschreg nschrp if nctdisad_2012_ter == 1, listwise
eststo control: estpost sum nctdisad_2012_ter nevercol ngender nrace nbirthy nlang nexpct ndisab nptype nnumhm nses npage nschtyp nschloc nschreg nschrp if nctdisad_2012_ter == 0, listwise
esttab treat control using "${output_directory}covariates_descriptives_3.rtf", main(mean) b(3) label ///
title("Summary statistics of covariates by treatment groups") mtitle("Treated" "Control") ///
nostar replace
eststo clear
*/
