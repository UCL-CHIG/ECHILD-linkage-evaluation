clear
qui do 				"S:\ECHILD_HES\Working\Max\projectLinkageEvaluationAllYears\do\0_global project filepaths.do"
cap 				log close
log 				using "${logdir}\q_uniqueAPMRsbyspringcensuslink_$S_DATE.log", replace 
timer				clear
timer				on 1 // start timer for whole do-file
/*==============================================================================
Project: 			ECHILD (linkage evaluation)
Purpose: 			Answer question: how many unique APMRs (=pupils) are there in each module by spring_census link status? (For Ruth's slide)
Author: 			maximiliane verfuerden
Created:			Mon 07 Jun 2021
Last modified:			Wed 09 Jun 2021
Last run:			Wed 09 Jun 2021
***
===============================================================================*/
use 				"${datadir_max}\ECHILD_aPMR_and_hesID_combinedbridgefiles.dta", clear
***Sorting the best pupil-patient matches to the front:***
**********************************************************
*transform matchstep variable so it corresponds to steps 1-8:
replace 			pds_matchstep=89999 if pds_matchstep==80
replace 			pds_matchstep=79999 if pds_matchstep==70
replace 			pds_matchstep=int(pds_matchstep/10000) 
*Making sure that those without matches (encrypted_hesid=.) get sorted furthest down:
replace				pds_matchstep = 9 if pds_matchstep==.
replace				hes_matchstep  = 9 if hes_matchstep==.
*Making sure that bad matches (=higher values) get sorted furthest down:
gen				    link_certainty = string(pds_matchstep) + "." + string(hes_matchstep)
drop				  *matchstep
*Add the link_certainty in front of the encrypted_hesid, so that the encrypted_hesid with the lowest (=more certain) values get sorted to the front:
replace				encrypted_hesid = link_certainty + "_" + encrypted_hesid
*What is the total number of unique APMRs?
bys 				  pupilmatchingrefanonymous: gen aPMRvals=_n 
count				  if aPMRvals ==1 
return				list
gen				    total_uniqueAPMRs = r(N)
count
*Sort the pupil-patient combinations:
sort			  	pupilmatchingrefanonymous encrypted_hesid // strongest matches come first
*What is the number of records within each patient-pupil combination?
bys				    pupilmatchingrefanonymous encrypted_hesid: gen recordval=_n
*Keep only the variables I am interested in:
keep				  pupilmatchingrefanonymous encrypted_hesid recordval link_certainty spring summer autumn plasc ap pru eyc eyfsp ks2 ks4 ks5 nccis 
*Reshape to wide, so there is one record per pupil-patient combination, with the strongest combination first (because I sorted on that earlier):
reshape				wide spring summer autumn plasc ap pru eyc eyfsp ks2 ks4 ks5 nccis, i(pupilmatchingrefanonymous) j(recordval)	
***Keep only the first/best pupil-patient match***
**************************************************
bys			  	pupilmatchingrefanonymous: gen matchnumber =_n
keep				if matchnumber ==1
count 			// now there is only 1 row for each unique pupil id (total number of records is = total_uniqueAPMRs, generated above)
***What is the number of unique pupils within each module?***
*************************************************************
foreach module in 		spring summer autumn plasc ap pru eyc eyfsp ks2 ks4 ks5 nccis {
egen				matched_to_`module' = anymatch(`module'*), values(1)
count				if matched_to_`module'==1
return			list
gen				  `module'_uniquepupils = r(N)
}
***What is the number of unique pupils within each module that do not link to the spring census?***
***************************************************************************************************
foreach module in 		summer autumn plasc ap pru eyc eyfsp ks2 ks4 ks5 nccis {
egen				matched_to_`module'_but_not_spring = anymatch(`module'*) if matched_to_spring == 0, values(1)
count				if matched_to_`module'_but_not_spring==1
return			list
gen				  `module'_not_spring_uniquepupils = r(N)
}
***Export as spreadsheet***
***************************
preserve
keep 				*unique*
duplicates	drop
format			*_* %10.0fc
*export count of unique IDs by NPD module and by springlinkstatus into a spreadsheet
export			delimited ${resultsdir}\ECHILDuniquePupilsBySpringcensus, replace	
restore				
*===============================================================================
timer				off 1
timer 			list 1
display as input "duration of this do-file: " r(t1) / 60 " minutes"
timer 			clear 
log 				close
