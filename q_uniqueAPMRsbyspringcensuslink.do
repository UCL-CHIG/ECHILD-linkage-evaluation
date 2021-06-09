clear
qui do 				"S:\ECHILD_HES\Working\Max\projectLinkageEvaluationAllYears\do\0_global project filepaths.do"
cap 				log close
log 				using "${logdir}\q_uniqueAPMRsbyspringcensuslink_$S_DATE.log", replace 
timer				clear
timer				on 1 // start timer for whole do-file
/*==============================================================================
Project: 			ECHILD - Max Verfuerden (my goal is to evaluate linkage)
Purpose: 			Answer question: how many unique APMRs (=pupils) are there in each module
					by spring_census link status?
Author: 			maximiliane verfuerden
Created:			Mon 07 Jun 2021
Last modified:		Tue 08 Jun 2021
Last run:			Tue 08 Jun 2021
***
===============================================================================*/
use 				"${datadir_max}\ECHILD_aPMR_and_hesID_combinedbridgefiles.dta", clear
sort				pupilmatchingrefanonymous
drop if				pupilmatchingrefanonymous =="" 
drop				encrypted*
*sort so that the best matches will get the aPMRvals==1
replace 			pds_matchstep=89999 if pds_matchstep==80
replace 			pds_matchstep=79999 if pds_matchstep==70
gen 				step_pds_matchstep=int(pds_matchstep/10000) 
gen 				year_pds_matchstep=pds_matchstep-int(pds_matchstep/10000)*10000
replace				pds_matchstep = step_pds_matchstep
drop				step_pds_matchstep
label var 			pds_matchstep "Step Linkage Stage 1"
label var 			year_pds_matchstep "Year Linkage Stage 1"
label var 			hes_matchstep "Step Linkage Stage 2"
sort				pupilmatchingrefanonymous pds_matchstep hes_matchstep  // making sure that those with better matchsteps come first
*what is total number of unique APMRs?
bys 				pupilmatchingrefanonymous: gen aPMRvals=_n 
count				if aPMRvals ==1 
return				list
gen					total_uniqueAPMRs = r(N)
count
* this must be an error there is a pupil with >5000 different records
drop				if aPMRvals>7
*total number according to module?
reshape				wide spring summer autumn plasc ap pru eyc eyfsp ks2 ks4 ks5 nccis total_uniqueAPMRs, i(pupilmatchingrefanonymous) j(aPMRvals)	
foreach module in spring summer autumn plasc ap pru eyc eyfsp ks2 ks4 ks5 nccis {
egen				`module' = anymatch(`module'*), values(1)
}
count
foreach module in spring summer autumn ap pru eyc eyfsp ks2 ks4 ks5 nccis {
bys					pupilmatchingrefanonymous: gen `module'_apmrval=_n if `module' ==1
count				if `module'_apmrval ==1 
return				list
gen					`module'_uniquepupils = r(N)
}
count
*total number according to module if not in spring census
foreach module in summer autumn ap pru eyc eyfsp ks2 ks4 ks5 nccis {
bys					pupilmatchingrefanonymous: gen `module'_notspring_apmrval=_n if `module' ==1 & spring ==0
count				if `module'_notspring_apmrval ==1 
return				list
gen					`module'_notspring_uniquepupils = r(N)
}		
*export as spreadsheet
preserve
drop 				pupilmatchingrefanonymous spring autumn summer plasc ap pru eyc eyfsp ks2 ks4 ks5 nccis *apmr*		
duplicates			drop
format				*_* %10.0fc
*export count of unique IDs by NPD module and by springlinkstatus into a spreadsheet
export				delimited ${resultsdir}\ECHILDuniquePupilsBySpringcensus, replace	
restore				
*===============================================================================
timer				off 1
timer 				list 1
display as input	"duration of this do-file: " r(t1) / 60 " minutes"
timer 				clear 
log 				close