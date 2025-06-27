clear all
set maxvar 30000
set more off

global output_directory "my_directory"
global input_directory "my_directory"

/*******************************************************************************
PROGRAM NAME: clean_hsls09.do
AUTHOR: Xia Zheng
PURPOSE: clean data from HSLS:09 base year to F2; rename, recode, or generate variables; merge with geocodes and nhood disadvantage index
NOTES: XZ created on 1/7/2024
*******************************************************************************/

/********************
INPUT AND RECODE DATA
*********************/

use "${input_directory}hsls_2016\data\f2student.dta", clear

keep STU_ID ///
	X4PSENRSTLV X4EVRATNDCLG X4HSCOMPSTAT ///
	X1SEX X1RACE X1STDOB X1NATIVELANG X1TXMTSCOR ///
	X1SCHOOLBEL X1SCHOOLENG X1STUEDEXPCT P1SLD ///
	X1PARPATTERN P1MARSTAT X1HHNUMBER P1YRBORN1 P1YRBORN2 X1SES ///
	X1CONTROL X1LOCALE X1REGION X1REPEAT9TH ///
	W4W1STUP1 
	
/*IDs*/
rename STU_ID nstuid
label var nstuid "unique student ID"

/*college enrollment*/
rename X4PSENRSTLV ncolenrol
label var ncolenrol "college enrollment status in Feb 2016"
recode ncolenrol (-9/-6 = .) (2/4 = 0)
label define ncolenrol_lbl 0 "not enrolled in 4-yr institutions" 1 "enrolled in 4-yr institutions"
label values ncolenrol ncolenrol_lbl 

/*ever attended college*/
rename X4EVRATNDCLG nevercol
label var nevercol "ever attended college by the end of Feb 2016"
recode nevercol (-8/-6 = .)
label define nevercol_lbl 0 "has never attended college after HS" 1 "has attended college after HS"
label values nevercol nevercol_lbl

/*high school completion status*/
rename X4HSCOMPSTAT nhsgrad
label var nhsgrad "high school completion status in Feb 2016"
recode nhsgrad (-8/-6 = .) (2 = 1) (3 = 0)
label define nhsgrad_lbl 0 "no HS credential" 1 "HS diploma or equivalency"
label values nhsgrad nhsgrad_lbl

tempfile master
save `master'

/*census tract ID and neighborhood disadvantage index*/
use "${input_directory}hsls_2009_geocodes\hsls09geocodes.dta", clear
keep STU_ID X2GTRACT X2GCNTY X2GSTATE X3GTRACT X3GCNTY X3GSTATE 
rename STU_ID nstuid
label var nstuid "unique student ID"
sort nstuid
gen nctid_2012 = X2GSTATE + X2GCNTY + X2GTRACT
gen nctid_2013 = X3GSTATE + X3GCNTY + X3GTRACT
label var nctid_2012 "student's 2012 census tract ID"
label var nctid_2013 "student's 2013 census tract ID"
keep n*
tempfile use1
save `use1'

use "${output_directory}v01_acs.dta", clear  
keep tt_id tt_year tt_disad
keep if tt_year == 2012 | tt_year == 2013
reshape wide tt_disad, i(tt_id) j(tt_year)
gen merge_id = tt_id
sort merge_id
tempfile use2
save `use2'

use `master'
sort nstuid
merge 1:1 nstuid using `use1', keep(1 3) nogenerate

gen merge_id = nctid_2012
sort merge_id
merge m:1 merge_id using `use2', keep(1 3) nogenerate
drop merge_id tt_disad2013
gen merge_id = nctid_2013
sort merge_id
merge m:1 merge_id using `use2', keep(1 3) nogenerate
drop merge_id tt_id

rename tt_disad2012 nctdisad_2012
label var nctdisad_2012 "census tract disadvantage index in 2012"
rename tt_disad2013 nctdisad_2013
label var nctdisad_2013 "census tract disadvantage index in 2013"

xtile nctdisad_2012_ter =  nctdisad_2012, nq(3)
xtile nctdisad_2012_qua =  nctdisad_2012, nq(4)
replace nctdisad_2012_ter = cond(missing(nctdisad_2012_ter), ., cond(nctdisad_2012_ter == 3, 1, 0))
replace nctdisad_2012_qua = cond(missing(nctdisad_2012_qua), ., cond(nctdisad_2012_qua == 4, 1, 0))
xtile nctdisad_2013_ter =  nctdisad_2013, nq(3)
xtile nctdisad_2013_qua =  nctdisad_2013, nq(4)
replace nctdisad_2013_ter = cond(missing(nctdisad_2013_ter), ., cond(nctdisad_2013_ter == 3, 1, 0))
replace nctdisad_2013_qua = cond(missing(nctdisad_2013_qua), ., cond(nctdisad_2013_qua == 4, 1, 0))

label var nctdisad_2012_ter "census tract disadvantage indicator(tertile) in 2012"
label var nctdisad_2012_qua "census tract disadvantage indicator(quartile) in 2012"
label var nctdisad_2013_ter "census tract disadvantage indicator(tertile) in 2013"
label var nctdisad_2013_qua "census tract disadvantage indicator(quartile) in 2013"

/*children's gender*/
rename X1SEX ngender
label var ngender "student's gender"
replace ngender = . if ngender == -9
replace ngender = 0 if ngender == 2
label define ngender_lbl 0 "female" 1 "male" 
label values ngender ngender_lbl 

/*children's race*/
rename X1RACE nrace
label var nrace "student's racial categories" 
recode nrace (-9 = .) (8 = 1) (1/7 = 0)
label define nrace_lbl 1 "white" 0 "non-white"
label values nrace nrace_lbl

/*children's birth year*/
replace X1STDOB = "." if X1STDOB == "-9"
gen nbirthy = substr(X1STDOB, 1, 4)
destring(nbirthy), replace
label var nbirthy "student's birth year"

/*student's native language*/
rename X1NATIVELANG nlang
label var nlang "student's native language"
recode nlang (-9 = .) (2/11 = 0)
label define nlang_lbl 1 "English" 0 "non-English"
label values nlang nlang_lbl

/*student's math standardized theta score*/
rename X1TXMTSCOR nmath
label var nmath "student's math standardized theta score"
replace nmath = . if nmath == -8

/*student's sense of school belonging scale*/
rename X1SCHOOLBEL nschbel
label var nschbel "student's sense of school belonging"
recode nschbel (-9/-8 = .)

/*student's school engagement scale*/
rename X1SCHOOLENG nscheng
label var nscheng "student's school engagement level"
recode nscheng (-9/-8 = .)

/*level of education student expects to achieve*/
rename X1STUEDEXPCT nexpct
label var nexpct "level of education student expects to achieve"
recode nexpct (-8 = .) (11 = .)

/*student's disability status*/
rename P1SLD ndisab
label var ndisab "student has learning disability"
recode ndisab (-9/-8 = .)
label define ndisab_lbl 1 "yes" 0 "no"
label values ndisab ndisab_lbl

/*type of parents living with the child*/
rename X1PARPATTERN nptype
label var nptype "type of parents living with student"
recode nptype (-9/-8 = .) (1/6 = 1) (7/11 = 0) 
label define nptype_lbl 1 "two bio/adoptive parents/guardians" 0 "one bio/adoptive parent/guardian only"
label values nptype nptype_lbl

/*parent's marital status*/
rename P1MARSTAT npmar
label var npmar "parent's marital status"
recode npmar (-9/-8 = .) (2/5 = 0)
label define npmar_lbl 1 "married" 0 "unmarried"
label values npmar npmar_lbl
	
/*number of household members*/
rename X1HHNUMBER nnumhm
label var nnumhm "number of household members"
recode nnumhm (-9/-8 = .) (2/5 = 1) (6/99 = 0)
label define nnumhm_lbl 1 "2-5 people" 0 "more than 5 people"
label values nnumhm nnumhm_lbl

/*parents/guardians' average birth year*/
recode P1YRBORN1 (-9/-8 = .)
recode P1YRBORN2 (-9/-7 = .)
egen pbirthyr = rowmean(P1YRBORN1 P1YRBORN2)
gen npage = 2009 - pbirthyr
label var npage "parents/guardians' average age in 2009"

/*household SES composite*/
rename X1SES nses
label var nses "household SES scale"
replace nses = . if nses == -8

/*school type*/
rename X1CONTROL nschtype
label var nschtype "school type"
recode nschtype (2/3 = 0)
label define nschtype_lbl 1 "public" 0 "private"
label values nschtype nschtype_lbl
	
/*locality type of school*/	
rename X1LOCALE nschloc
label var nschloc "school's location type"
recode nschloc (1/2 = 0) (3/4 = 1)
label define nschloc_lbl 0 "city or suburb" 1 "town or rural"
label values nschloc nschloc_lbl

/*geographic region of school*/
rename X1REGION nschreg
label var nschreg "school's geographic region"
label define nschreg_lbl 1 "northeast" 2 "midwest" 3 "south" 4 "west"
label values nschreg nschreg_lbl

/*percent of 9th graders repeating 9th grade*/
rename X1REPEAT9TH nschrp
label var nschrp "percent of 9th graders repeating 9th grade at school"
recode nschrp (-9/-8 = .) (0/1 = 1) (2/5 = 0)
label define nschrp_lbl 1 "less than 5%" 0 "5% or more"
label values nschrp nschrp_lbl

/*sample weight*/
rename W4W1STUP1 nsampwt
label var nsampwt "student longitudinal analytic weight"

/********
SAVE DATA
*********/
keep n* 
save "${output_directory}hsls_BYF2_procd_test.dta", replace

