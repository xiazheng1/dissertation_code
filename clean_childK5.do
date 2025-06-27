clear all
set maxvar 30000
set more off

global output_directory "my_directory"
global input_directory "my_directory"

/*******************************************************************************
PROGRAM NAME: clean_childK5.do
AUTHOR: Xia Zheng
PURPOSE: clean data from ECLS-K:2011 K-5 file; rename variables; create new variables
NOTES: XZ created on 12/2/2022; modified 10/27/2023
*******************************************************************************/

/********************
INPUT AND RECODE DATA
*********************/

use "${input_directory}childK5.dta", clear

keep CHILDID ///
	X6RTHETK5-X9RTHETK5 X6RSETHK5-X9RSETHK5 ///
	X6MTHETK5-X9MTHETK5  X6MSETHK5-X9MSETHK5 ///
	X6STHETK5-X9STHETK5  X6SSETHK5-X9SSETHK5 ///
	X6TCHCON-X9TCHCON  X6TCHPER-X9TCHPER  X6TCHEXT-X9TCHEXT  X6TCHINT-X9TCHINT ///
	X6TCHAPP-X9TCHAPP ///
	X6ATTMCQ-X9ATTMCQ ///
	X6INTMCQ-X9INTMCQ ///
	P2CENTRC P4CENTRC P6CENTRC-P8CENTRC F2CENTRC ///
	X_CHSEX_R X_DOBYY_R X_RACETH_R X2DISABL X12LANGST X2SPECS ///
	X2HTOTAL X2HPARNT X2PAR1AGE X12MOMAR X12SESL ///
	X2PUBPRI X2KENRLS X2KRCETH X2FLCH2_I X2REGION X2LOCALE ///
	W9C29P_2T290 
	
/*IDs*/
rename CHILDID ncid
label var ncid "unique child ID"


/*cognitive skills*/

local i = 2							
foreach var of varlist X6RTHETK5-X9RTHETK5 {                
	replace `var' = . if `var' > 4 | `var' < -4
	rename `var' nread_sp`i'
	label var nread_sp`i' "reading theta scores for spring `i' grade"
	local i = `i' + 1
}

       
local i = 2							
foreach var of varlist X6RSETHK5-X9RSETHK5 {                
	rename `var' nreadse_sp`i'
	label var nreadse_sp`i' "reading standard error for spring `i' grade"
	local i = `i' + 1
}

local i = 2							
foreach var of varlist X6MTHETK5-X9MTHETK5 {                
	replace `var' = . if `var' > 4 | `var' < -4
	rename `var' nmath_sp`i'
	label var nmath_sp`i' "math theta scores for spring `i' grade"
	local i = `i' + 1
}
  
local i = 2							
foreach var of varlist X6MSETHK5-X9MSETHK5 {                
	rename `var' nmathse_sp`i'
	label var nmathse_sp`i' "math standard error for spring `i' grade"
	local i = `i' + 1
}

local i = 2							
foreach var of varlist X6STHETK5-X9STHETK5 {                
	replace `var' = . if `var' > 4 | `var' < -4
	rename `var' nscience_sp`i'
	label var nscience_sp`i' "science theta scores for spring `i' grade"
	local i = `i' + 1
}

local i = 2							
foreach var of varlist X6SSETHK5-X9SSETHK5 {                
	rename `var' nsciencese_sp`i'
	label var nsciencese_sp`i' "science standard error for spring `i' grade"	
	local i = `i' + 1
}
									

/*social and emotional skills*/

local i = 2							
foreach var of varlist X6TCHCON-X9TCHCON {
	replace `var' = . if `var' > 4 | `var' < 1
	rename `var' nselfctl_sp`i'
	label var nselfctl_sp`i' "self-control scale for spring `i' grade"
	local i = `i' + 1
}

local i = 2							
foreach var of varlist X6TCHPER-X9TCHPER {                
	replace `var' = . if `var' > 4 | `var' < 1
	rename `var' ninterperson_sp`i'
	label var ninterperson_sp`i' "interpersonal scale for spring `i' grade"	
	local i = `i' + 1
}

local i = 2							
foreach var of varlist X6TCHEXT-X9TCHEXT {               
	replace `var' = . if `var' > 4 | `var' < 1
	rename `var' nexprobbehav_sp`i'
	label var nexprobbehav_sp`i' "externalizing problem behaviors scale for spring `i' grade"	
	local i = `i' + 1
}


local i = 2							
foreach var of varlist X6TCHINT-X9TCHINT {              
	replace `var' = . if `var' > 4 | `var' < 1
	rename `var' ninprobbehav_sp`i'
	label var ninprobbehav_sp`i' "internalizing problem behaviors scale for spring `i' grade"	
	local i = `i' + 1
}


local i = 2							
foreach var of varlist X6TCHAPP-X9TCHAPP {           
	rename `var' napplearn_sp`i'
	replace napplearn_sp`i' = . if napplearn_sp`i' > 4 | napplearn_sp`i' < 1	
	label var napplearn_sp`i' "approaches to learning scale for spring `i' grade"
	local i = `i' + 1
}


local i = 2							
foreach var of varlist X6ATTMCQ-X9ATTMCQ {
	replace `var' = . if `var' > 5 | `var' < 1          
	rename `var' nattfoc_sp`i'
	label var nattfoc_sp`i' "attentional focus scale for spring `i' grade"
	local i = `i' + 1
}
	
local i = 2							
foreach var of varlist X6INTMCQ-X9INTMCQ {
	replace `var' = . if `var' > 5 | `var' < 1           
	rename `var' ninhibctl_sp`i'
	label var ninhibctl_sp`i' "inhibitory control scale for spring `i' grade"
	local i = `i' + 1
}



/*census tract ID and neighborhood disadvantage index for spring 1,2,3,4 grades*/

rename P4CENTRC nctid_sp1
label var nctid_sp1 "children's home census tract ID for spring 1 grade"
local i = 2						
foreach var of varlist P6CENTRC-P8CENTRC {           
	rename `var' nctid_sp`i'
	label var nctid_sp`i' "children's home census tract ID for spring `i' grade"
	local i = `i' + 1
}

tempfile master1
save `master1'

use "${output_directory}v01_acs.dta", clear     // I can only keep my data in this directory.
keep tt_id tt_year tt_disad
keep if tt_year == 2012 | tt_year == 2013 | tt_year == 2014 | tt_year == 2015
reshape wide tt_disad, i(tt_id) j(tt_year)
gen merge_id = tt_id
sort merge_id
tempfile using1
save `using1'

use `master1'
gen merge_id = nctid_sp1
sort merge_id
merge m:1 merge_id using `using1', keep(1 3) nogenerate
drop merge_id tt_disad2013-tt_disad2015

gen merge_id = nctid_sp2
sort merge_id
merge m:1 merge_id using `using1', keep(1 3) nogenerate
drop merge_id tt_disad2014-tt_disad2015

gen merge_id = nctid_sp3
sort merge_id
merge m:1 merge_id using `using1', keep(1 3) nogenerate
drop merge_id tt_disad2015

gen merge_id = nctid_sp4
sort merge_id
merge m:1 merge_id using `using1', keep(1 3) nogenerate
drop merge_id tt_id

local i = 1						
foreach var of varlist tt_disad2012-tt_disad2015 {           
	rename `var' nctdisad_sp`i'
	label var nctdisad_sp`i' "census tract disadvantage index for spring `i' grade"
	
	xtile nctdisad_sp`i'_ter =  nctdisad_sp`i', nq(3)
	xtile nctdisad_sp`i'_qua =  nctdisad_sp`i', nq(4)
	xtile nctdisad_sp`i'_qui =  nctdisad_sp`i', nq(5)
	replace nctdisad_sp`i'_ter = cond(missing(nctdisad_sp`i'_ter), ., cond(nctdisad_sp`i'_ter == 3, 1, 0))
	replace nctdisad_sp`i'_qua = cond(missing(nctdisad_sp`i'_qua), ., cond(nctdisad_sp`i'_qua == 4, 1, 0))
	replace nctdisad_sp`i'_qui = cond(missing(nctdisad_sp`i'_qui), ., cond(nctdisad_sp`i'_qui == 5, 1, 0))
	
	label var nctdisad_sp`i'_ter "census tract disadvantage indicator(tertile) for spring `i' grade"
	label var nctdisad_sp`i'_qua "census tract disadvantage indicator(quartile) for spring `i' grade"
	label var nctdisad_sp`i'_qui "census tract disadvantage indicator(quintile) for spring `i' grade"
		
	local i = `i' + 1
	
}


/*children's gender*/
rename X_CHSEX_R ngender
label var ngender "children's gender"
replace ngender = . if ngender == -9
replace ngender = 0 if ngender == 2
label define ngender_lbl 0 "female" 1 "male" 
label values ngender ngender_lbl 

/*children's birth year*/
rename X_DOBYY_R nbirthy
replace nbirthy = . if nbirthy == -9
label var nbirthy "children's birth year"

/*children's race*/
rename X_RACETH_R nrace
label var nrace "children's racial categories" 
recode nrace (-9 = .) (3/4 = 3) (5 = 4) (6/8 = 5)
label define nrace_lbl 1 "white" 2 "black" 3 "hispanic" 4 "asian" 5 "other"
label values nrace nrace_lbl


/*children's disability status*/
rename X2DISABL ndisab
label var ndisab "child has disability"
replace ndisab = . if ndisab == -9
replace ndisab = 0 if ndisab == 2
label define ndisab_lbl 1 "yes" 0 "no"
label values ndisab ndisab_lbl


/*children's primary language at home*/
rename X12LANGST nlang
label var nlang "children's language at home"
replace nlang = . if nlang == -9
label define nlang_lbl 1 "non-english" 2 "english" 3 "more than one language"
label values nlang nlang_lbl

/*chidlren's receipt of special education services*/
rename X2SPECS nspedu
label var nspedu "children linked to a special education teacher"
replace nspedu = 0 if nspedu == 2
label define nspedu_lbl 1 "linked to a special ed teacher" 0 "not linked to a special ed teacher"
label values nspedu nspedu_lbl
	
/*total number of persons in the household */
rename X2HTOTAL nfnumhm
label var nfnumhm "number of persons in household"
replace nfnumhm = . if nfnumhm == -9

/*type of parents living with the child*/
rename X2HPARNT nfptype
label var nfptype "types of parents in household"
replace nfptype = . if nfptype == -9
label define nfptype_lbl 1 "two biological/adoptive parents" 2 "one biological/adoptive parent and one other parent" ///
						3 "one biological/adoptive parent only" 4 "other guardians(e.g. grandparents)"
label values nfptype nfptype_lbl

/*age of the primary caregiver*/
rename X2PAR1AGE nfpage
label var nfpage "age of the primary caregiver"
replace nfpage = . if nfpage == -9

/*whether parents were married at time of the child's birth*/
rename X12MOMAR nfpmarried
label var nfpmarried "parents were married at time of birth"
replace nfpmarried = . if nfpmarried == -9
replace nfpmarried = 0 if nfpmarried == 2
label define nfpmarried_lbl 1 "yes" 0 "no"
label values nfpmarried nfpmarried_lbl


/*SES composite of the household created by parents' edu, occu prestige score, household income*/
rename X12SESL nfhses
label var nfhses "household SES composite scale"
replace nfhses = . if nfhses == -9

/*school type(public/private)*/
rename X2PUBPRI nschtype
label var nschtype "school type"
replace nschtype = . if nschtype == -9 | nschtype == -1
replace nschtype = 0 if nschtype == 2
label define nschtype_lbl 1 "public" 0 "private"
label values nschtype nschtype_lbl
	
/*total school enrollment*/	
rename X2KENRLS nschenroll
label var nschenroll "total school enrollment categories"
recode nschenroll (-9/-1 = .) (1/2 = 1) (3/4 = 2) (5 = 3)
label define nschenroll_lbl 1 "less than 300" 2 "300 to 749" 3 "750 and above"
label values nschenroll nschenroll_lbl
	
/*percent of non-white students*/
rename X2KRCETH nschpnonwh
label var nschpnonwh "percent of nonwhite students in school"
replace nschpnonwh = . if nschpnonwh == -9 | nschpnonwh == -1
	
/*percent of students approved for free lunch*/	
rename X2FLCH2_I nschpfl
label var nschpfl "percent of students eligible for free lunch"
replace nschpfl = . if nschpfl == -9 | nschpfl == -1

/*geographic region of school*/
rename X2REGION nschreg
label var nschreg "census region of school"
replace nschreg = . if nschreg == -9 | nschreg == -1
label define nschreg_lbl 1 "northeast" 2 "midwest" 3 "south" 4 "west"
label values nschreg nschreg_lbl

/*locality type of school*/	
rename X2LOCALE nschloc
label var nschloc "location type of school"
recode nschloc (-9/-1 = .) (11/13 = 1) (21/23 = 2) (31/33 = 3) (41/43 = 4)
label define nschloc_lbl 1 "city" 2 "suburb" 3 "town" 4 "rural"
label values nschloc nschloc_lbl

/*rural-urban continuum codes of children's school and home*/
rename F2CENTRC nsctid_sp0
replace nsctid_sp0 = "" if nsctid_sp0 == "-9"
label var nsctid_sp0 "children's school census tract ID for spring kindergarten"
rename P2CENTRC nctid_sp0
label var nctid_sp0 "children's home census tract ID for spring kindergarten"
tempfile master2
save `master2'

use "${output_directory}ruralurbancodes2013.dta", clear
drop if RUCC_2013 == .
keep FIPS RUCC_2013
gen merge_id = FIPS
sort merge_id
tempfile using2
save `using2'

use `master2'
gen merge_id = substr(nsctid_sp0, 1, 5)
sort merge_id
merge m:1 merge_id using `using2', keep(1 3) nogenerate
drop merge_id
rename RUCC_2013 nschrucc	
label var nschrucc "school rural-urban continuum code(1 being highest metro proximity)"

gen merge_id = substr(nctid_sp0, 1, 5)
sort merge_id
merge m:1 merge_id using `using2', keep(1 3) nogenerate
drop merge_id FIPS
rename RUCC_2013 nfrucc	
label var nfrucc "home rural-urban continuum code(1 being highest metro proximity)"


/*sample weight*/
rename W9C29P_2T290 nsampwt
label var nsampwt "sample weight"

/*cognitive skill and socio-emotional skill scale construction with principal factor analysis with iterations and a varimax rotation*/
//extract three factors for all waves: 
//cognitive skills(reading, math, science scores)(higher scores indicate higher cognitive skills)
//social skills(self control scale, interpersonal scale, externalizing problem behavior scale, internalizing problem behavior scale)(higher scores mean the child exhibited behaviors beneficial to social interactions more often)
//approaches to learning(approaches to learning scale, attentional focus scale, inhibitory control scale)(higher scores mean the child exhibited more behaviors beneficial to learning)
//The social skills scale and approaches to learning scale constructed in this section were not used in chapter 2 analyses.

//reverse the scaling of the component negatively related to the underlying factor
forval i = 2/5 {
	sum nexprobbehav_sp`i', meanonly
	gen double r_nexprobbehav_sp`i' = r(max)-nexprobbehav_sp`i'+1   

	sum ninprobbehav_sp`i', meanonly
	gen double r_ninprobbehav_sp`i' = r(max)-ninprobbehav_sp`i'+1  
}

//predict the factor scores for the three factors. Only the cognitive skill scale was used.
forval i = 2/4 {
	factor nread_sp`i' nmath_sp`i' nscience_sp`i' nselfctl_sp`i' ninterperson_sp`i' r_nexprobbehav_sp`i' r_ninprobbehav_sp`i' ///
	napplearn_sp`i' nattfoc_sp`i' ninhibctl_sp`i', ipf
	rotate
	predict applearns_sp`i' soc_sp`i' cog_sp`i'
}
//for sp5, the first extracted factor is social skill instead of approaches to learning
factor nread_sp5 nmath_sp5 nscience_sp5 nselfctl_sp5 ninterperson_sp5 r_nexprobbehav_sp5 r_ninprobbehav_sp5 ///
	   napplearn_sp5 nattfoc_sp5 ninhibctl_sp5, ipf
rotate
predict soc_sp5 applearns_sp5 cog_sp5

//standardize the cognitive skill scale
forval i = 2/5 {
	sum cog_sp`i'
	gen ncog_sp`i' = (cog_sp`i' - r(mean)) / r(sd)
	label var ncog_sp`i' "standardized cognitive skill scale for spring `i' grade"
	sum ncog_sp`i'   //after standardization, each score should have a mean of 0 and a standard deviation of 1
}

drop applearns_sp* soc_sp*

//revised factor analysis for socioemotional skill scale construction
//predict the factor scores of the approach to learning and social skill scales(exprobbehav and inprobbehav are not included because they are not highly related to any underlying factors)
forval i = 2/5 {
	factor nselfctl_sp`i' ninterperson_sp`i' ///
	napplearn_sp`i' nattfoc_sp`i' ninhibctl_sp`i', ipf
	rotate
	predict applearns_sp`i' soc_sp`i'
}

//standardize the two resulting scales
forval i = 2/5 {
	sum applearns_sp`i'
	gen napplearns_sp`i' = (applearns_sp`i' - r(mean)) / r(sd)
	label var napplearns_sp`i' "standardized approaches to learning scale for spring `i' grade"
	sum napplearns_sp`i'
	
	sum soc_sp`i'
	gen nsoc_sp`i' = (soc_sp`i' - r(mean)) / r(sd)
	label var nsoc_sp`i' "standardized social skill scale for spring `i' grade"
	sum nsoc_sp`i'
}

//standardize the externalizing and internalizing problem behavior scales and include them as independent scales
forval i = 2/5 {
	sum nexprobbehav_sp`i'
	gen nexprobbehavs_sp`i' = (nexprobbehav_sp`i' - r(mean)) / r(sd)
	label var nexprobbehavs_sp`i' "standardized externalizing problem behavior scale for spring `i' grade"
	sum nexprobbehavs_sp`i'

	sum ninprobbehav_sp`i'
	gen ninprobbehavs_sp`i' = (ninprobbehav_sp`i' - r(mean)) / r(sd)
	label var ninprobbehavs_sp`i' "standardized internalizing problem behavior scale for spring `i' grade"
	sum ninprobbehavs_sp`i'
}

/********
SAVE DATA
*********/
keep n* 
save "${output_directory}childK5_procd.dta", replace