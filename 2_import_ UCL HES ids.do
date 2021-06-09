clear
qui do 				"S:\ECHILD_HES\Working\Max\projectLinkageEvaluationAllYears\do\0_global project filepaths.do"
cap 				log close
log 				using "${logdir}\import_UCL_HES_IDS_$S_DATE.log", replace 
timer				clear
timer				on 1 // start timer for whole do-file
timer 				on 2 // start timer for loop 1
timer 				on 3 // start timer for loop 2
timer 				on 4 // start timer for loop 3
/*==============================================================================
Project: 			ECHILD - Max Verfuerden (my goal is to evaluate linkage)
Purpose: 			imports the UCL HES module csv files into stata and extracts: 
					encrypted hesid, birth cohort, age at first link, module and hes year
Author: 			maximiliane verfuerden
Created:			Thu 22 Apr 2021
Last modified:		Wed 05 May 2021
Last run:			Wed 05 May 2021
***
technical notes:    -cap = skip over empty files (suppresses error message in loop)
					-timeloop = a program written and defined in the filepaths do-file
					-filepaths can be checked / changed by looking at the following do-file:
					"S:\ECHILD_HES\Working\Max\projectLinkageEvaluationAllYears\do\0-globaldirectories.do" 
===============================================================================*/
*import all hes module files from csv into stata and create variables that contain cohort, hes year and module information for each hesid
foreach				module in ae apc op deaths {   // 30 Apr 21: cc does not contain hes id?? //  
foreach    			birthyear in data95_00 data00_07 data07_13 data13_20 {
cd 					"${`birthyear'}"
local 				myfilelist : dir . files "*`module'*.csv" 
di 					`myfilelist'  // show me all files in the birthyear directory that correspond to the module we are looping through atm
foreach file of local myfilelist { 
cap local 			hesyear= substr("`file'", -6, 2) // extract hes year from file name
cap	di				"`hesyear'"
cap local 			cohort= substr("`file'", 1, 5)  // extract birth cohort from file name
di 					"`cohort'"
cap import 			delimited "`file'", encoding(ISO-8859-2) clear // import file into stata
cap gen				cohort= "`cohort'"		// generate a variable that saves the birthcohort this hesid belongs to
cap gen				hesyear= "`hesyear'"	// generate a variable that saves in which hes year this hesid had hospital contact
cap gen				hesmodule= "`module'"	// generate a variable that saves in which hes module we can find data for this hesid 
cap keep			encrypted_hesid *age* *date* cohort hesyear hesmodule
cap duplicates		drop
cap compress
cap save 			"${hes_modulebycohort_max}\hes_`module'_`cohort'_`hesyear'.dta", replace 
timeloop1
}
timeloop2
}
timeloop3
}
********************************************************************************
*create one file for each module containing data on birthcohort and hes year (not deaths because it doesnt contain hesyear)
timer on			5
foreach				module in ae apc op {  
cd 					"${hes_modulebycohort_max}"
local 				moduledata : dir . files "hes_`module'_b*.dta" 
di 					`moduledata' 
use					"${hes_modulebycohort_max}\hes_`module'_b1995_14.dta", clear
foreach file of local moduledata {
append 				using "`file'", force
}
save				"${hes_temp}\hes_`module'_temp.dta", replace
}
*create one file for deaths module containing data on birthcohort (no hesyear available)
cd 					"${hes_modulebycohort_max}"
local 				moduledata2 : dir . files "hes_deaths_b*.dta" 
di 					`moduledata2' 
use					"${hes_modulebycohort_max}\hes_deaths_b1995_hs.dta", clear
foreach file of local moduledata2 {
append 				using "`file'", force
}
save				"${hes_temp}\hes_deaths_temp.dta", replace
timer				off 5
timer 				list 5 
display as input	"duration of this section: " round(r(t5) / 60) " minutes"
********************************************************************************
timer on			6
*a&e - only keep the first link: 
use					"${hes_temp}\hes_ae_temp.dta", clear
cap keep			encrypted_hesid arrivalage arrivaldate hesyear cohort hesmodule
sort				encrypted_hesid arrivaldate arrivalage 
bys 				encrypted_hesid: gen id=_n
keep				if id==1
drop				id arrivaldate
rename				arrivalage age_firstlink_ae
compress
save				"${hes_idsbymodule_max}\hes_ae_uniqueids.dta", replace
*apc - only keep the first link: 
use					"${hes_temp}\hes_apc_temp.dta", clear
cap keep			encrypted_hesid admiage admidate hesyear cohort hesmodule
sort				encrypted_hesid admidate admiage 
bys 				encrypted_hesid: gen id=_n
keep				if id==1
drop				id admidate
rename				admiage age_firstlink_apc
compress
save				"${hes_idsbymodule_max}\hes_apc_uniqueids.dta", replace
*outpatients - only keep the first link: 
use					"${hes_temp}\hes_op_temp.dta", clear
cap keep			encrypted_hesid apptage apptdate hesyear cohort hesmodule
sort				encrypted_hesid apptdate apptage 
bys 				encrypted_hesid: gen id=_n
keep				if id==1
drop				id apptdate
rename				apptage age_firstlink_op
duplicates			drop
compress
save				"${hes_idsbymodule_max}\hes_op_uniqueids.dta", replace
*deaths age at link: 
use					"${hes_temp}\hes_deaths_temp.dta", clear
cap keep			encrypted_hesid age_at_death cohort hesmodule
sort				encrypted_hesid age_at_death 
bys 				encrypted_hesid: gen id=_n
keep				if id==1
drop				id 
rename				age_at_death age_firstlink_deaths
duplicates			drop
compress
save				"${hes_idsbymodule_max}\hes_deaths_uniqueids.dta", replace
timer				off 6
timer 				list 6
display as input	"duration of this section: " round(r(t6) / 60) " minutes"
********************************************************************************
timer on			7
*create one dataset with unique hes ids for all HES modules (except critical care)
use					"${hes_idsbymodule_max}\hes_deaths_uniqueids.dta", clear
foreach				module in ae apc op {
append				using "${hes_idsbymodule_max}\hes_`module'_uniqueids.dta", force
}
keep				encrypted_hesid hesmodule cohort age_first*  // change this!!! I want to preserve all cohort information (as it differs for some across these datasets) but need a more efficient way to do this also keep hesyear.
duplicates			drop	
dropmiss, force	
bys 				encrypted_hesid: gen id=_n
reshape				wide cohort age_first* hes*, i(encrypted_hesid) j(id)
duplicates			drop
dropmiss, force				
compress
cap drop			cohort2 cohort3 cohort4 
order				encrypted_hesid cohort* age_first* 
gen					ae = .
gen					apc = .
gen					op = .
gen					deaths =.
foreach				module in ae apc op deaths {
foreach				var of varlist hesmodule* {
replace				`module' = 1 if strpos(`var', "`module'")==1
}
}
drop				hesmodule* hesyear*
gen					cohort = .
replace				cohort = 1 if strpos(cohort1, "b1995")==1
replace				cohort = 2 if strpos(cohort1, "b2000")==1
replace				cohort = 3 if strpos(cohort1, "b2007")==1
replace				cohort = 4 if strpos(cohort1, "b2013")==1
drop				cohort1
lab	def 			cohortlb 1 "born 1995 to 2000 (hesyr)" ///
					2 "born Sept 2000 to Aug 2007" ///
					3 "born Sept 2007 to Aug 2013" ///
					4 "born Sept 2013 to Mar 2020" 
lab					val cohort cohortlb
lab					var cohort "birthcohort"
sort				cohort	
order				cohort		
egen				age_firstlink_ae = rowmin(age_firstlink_ae*)
egen				age_firstlink_deaths = rowmin(age_firstlink_deaths*)
egen				age_firstlink_apc = rowmin(age_firstlink_apc*)
egen				age_firstlink_op = rowmin(age_firstlink_op*) // lots of 
drop				*1 *2 *3 *4
compress
save				"${hesdata_max}\hes_ids_cohorts_modules_95to20.dta", replace
timer				off 7
timer 				list 7
display as input	"duration of this section: " round(r(t7) / 60) " minutes"
*===============================================================================
timer				off 1 
timer 				list 1 
display as input	"duration of this do-file: " round(r(t1) / 60) " minutes"
timer 				clear 