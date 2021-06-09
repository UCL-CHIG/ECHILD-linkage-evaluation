clear
qui do 				"S:\ECHILD_HES\Working\Max\projectLinkageEvaluationAllYears\do\0_global project filepaths.do"
cap 				log close
log 				using "${logdir}\importECHILDBridgeFilestoStata $S_DATE.log", replace 
timer				clear
timer				on 1
/*==============================================================================
Project: 			ECHILD - Max Verfuerden
Purpose: 			imports the bridge files into stata, merges them all
					describes how many unique aPMRs and HES ids are in each linkage file - saves this in csv table
					filepaths can be checked / changed by looking at the following do-file:
					"S:\ECHILD_HES\Working\Max\projectLinkageEvaluationAllYears\do\0-globaldirectories.do" 
Author: 			maximiliane verfuerden
Created:			09 Apr 2021
Last run:			12 Apr 2021
Last updated:		07 Jun 2021 - needed to find out unique pupils rather than pupil-hes combinations
===============================================================================*/
* read in csv bridge files & save in dta format
local files : 		dir "${echild_datadir}" files "*.txt"
foreach 			f in `files' {
display 			"`f'"
local F 			"\`f'"
clear
import 				delimited "${echild_datadir}/`F'", encoding(ISO-8859-2) 
duplicates 			drop
gen 				source="`f'"
gen 				source2=substr(source,11,.)
gen 				len = strlen(source2)
gen 				end = (strpos(source2,"_")-1)
gen 				source3=substr(source2,1,end)
local 				name = source3[_N]
disp 				"`name'"
gen 				`name' = 1
save 				"${npdfiles_max}\ECHILD_aPMR_and_hesID_`name'.dta", replace
}
*combine the bridge files into a single file
use 				"${npdfiles_max}\ECHILD_aPMR_and_hesID_plasc.dta", clear
foreach				name in ap pru eyc eyfsp ks2 ks4 ks5 nccis {
append 				using "${npdfiles_max}\ECHILD_aPMR_and_hesID_`name'.dta"
}
drop				source* len end
sort 				pupilmatchingrefanonymous 
order				pupilmatchingrefanonymous encrypted_hesid
save 				"${datadir_max}\ECHILD_aPMR_and_hesID_combinedbridgefiles.dta", replace
*create files that only contain unique pupils for each module
foreach				name in plasc ap pru eyc eyfsp ks2 ks4 ks5 nccis {
use 				"${npdfiles_max}\ECHILD_aPMR_and_hesID_`name'.dta", clear
sort				pupilmatchingrefanonymous pds_matchstep hes_matchstep
by					pupilmatchingrefanonymous, sort: gen aPMRvals = _n
count				if aPMRvals ==1 
return				list
gen					nr_uniqueAPMRs = r(N)
by					encrypted_hesid, sort: gen hesIDvals = _n
count				if hesIDvals ==1 
return				list
gen					nr_uniqueHESIDs = r(N)
keep 				if aPMRvals ==1 // only keep unique APMRs (=pupils) in this file
disp 				"`name'"
gen					module = "`name'"
order				module nr_uniqueAPMRs nr_uniqueHESIDs
duplicates			drop
keep				module nr_uniqueAPMRs nr_uniqueHESIDs
save 				"${npdfiles_max}\temp_`name'.dta", replace
}
*how many unique apmrs are there in all NPD modules combined?
use 				"${datadir_max}\ECHILD_aPMR_and_hesID_combinedbridgefiles.dta", clear
by					pupilmatchingrefanonymous, sort: gen aPMRvals = _n
count				if aPMRvals ==1 
return				list
gen					nr_uniqueAPMRs = r(N)
by					encrypted_hesid, sort: gen hesIDvals = _n
count				if hesIDvals ==1 
return				list
gen					nr_uniqueHESIDs = r(N)
gen					module = "npdModulesCombined"
keep 				if aPMRvals ==1 // only keep unique APMRs (=pupils) in this file
order				module nr_uniqueAPMRs nr_uniqueHESIDs
keep				module nr_uniqueAPMRs nr_uniqueHESIDs 
duplicates			drop
save 				"${npdfiles_max}\temp_npdModulesCombined.dta", replace
*append files to generate one csv file containing unique apmrs in each NPD module and for all NPD modules combined
use					"${npdfiles_max}\temp_nccis.dta", clear
foreach				name in plasc ap pru eyc eyfsp ks2 ks4 ks5 nccis npdModulesCombined {
append 				using "${npdfiles_max}\temp_`name'.dta"
erase				"${npdfiles_max}\temp_`name'.dta"
}
*drop duplicates in terms of all variables
duplicates			drop
format				nr_uniqueAPMRs %10.0fc
format				nr_uniqueHESIDs %10.0fc
*export count of unique IDs by NPD module and for allNPD  modules combined into a spreadsheet
export				delimited ${resultsdir}\ECHILDuniquePupilsInLinkageFiles, replace
*===============================================================================
timer				off 1
timer 				list 1
display as input	"duration of this do-file: " r(t1) / 60 " minutes"
timer 				clear 
log 				close