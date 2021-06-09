clear
qui do 				"S:\ECHILD_HES\Working\Max\projectLinkageEvaluationAllYears\do\0_global project filepaths.do"
cap 				log close
log 				using "${logdir}\Assign_link_status_$S_DATE.log", replace 
timer				clear
timer				on 1
/*==============================================================================
Project: 			ECHILD - Max Verfuerden
Purpose: 			Assign a link status variable to the pupil-patient pairs and
					creates a csv spreadsheet that lists the status and steps
Created:			13 Apr 2021
Last run:			Mon 6 May 2021
Edit history:		Mon 26 April 2021
					Thu 6 May 2021
===============================================================================*/
use 				"${datadir_max}\ECHILD_aPMR_and_hesID_combinedbridgefiles.dta"
*linked to PDS 
gen 				linked_NPD_PDS=.
replace 			linked_NPD_PDS=1 if pupilmatchingrefanonymous!="" & pds_matchstep!=. // NPD-PDS 
replace 			linked_NPD_PDS=2 if pupilmatchingrefanonymous!="" & pds_matchstep==. // Excluded: fails to link to PDS 
*linked to PDS and general HES 
gen 				linked_NPD_PDS_HES=.
replace 			linked_NPD_PDS_HES=1 if pupilmatchingrefanonymous!="" & pds_matchstep!=. & encrypted_hesid!="" // NPD-PDS-HES
replace 			linked_NPD_PDS_HES=2 if pupilmatchingrefanonymous!="" & pds_matchstep!=. & encrypted_hesid=="" // Excluded: fails to link 
*linked to PDS, general HES and UCL HES
gen 				linked_NPD_PDS_HES_UCLHES=.
merge				m:1 encrypted_hesid using "${hesdata_max}\hes_ids_cohorts_modules_95to20.dta"
replace				linked_NPD_PDS_HES_UCLHES =1 if linked_NPD_PDS_HES==1 & _merge==3 // matched at all steps
replace				linked_NPD_PDS_HES_UCLHES =2 if _merge==2 // part of UCL HES but not in ECHILD hesid cohort
replace				linked_NPD_PDS_HES_UCLHES =3 if _merge==1 // part of ECHILD cohort but not matched to UCL HES
drop				_merge
*create a link status variable
gen 				link_status=.
replace 			link_status=1  if linked_NPD_PDS_HES_UCLHES==1
replace 			link_status=2  if linked_NPD_PDS_HES==1 & linked_NPD_PDS_HES_UCLHES!=1
replace 			link_status=3  if linked_NPD_PDS==1 & linked_NPD_PDS_HES==2
replace 			link_status=4  if linked_NPD_PDS==2
replace 			link_status=5  if linked_NPD_PDS_HES_UCLHES==2
label 				define link_statuslb 1 "Linked NPD-PDS-HES-UCLHES" 2 "no link to UCL HES" 3 "no link to NHS-D HES" 4 "no link to PDS" 5"part of UCL HES but not in ECHILD", replace 
label 				val link_status link_statuslb
drop				linked_NPD*
*drop duplicates in terms of all variables
duplicates			drop
*create variables that indicate how often a given ID (npd and HES ID) has been matched
// I checked, all pupilref and HES id combinations are unique
bys 				pupilmatchingrefanonymous: gen n_npdid=_n if pupilmatchingrefanonymous!="" 
bys 				encrypted_hesid: gen n_hesid=_n if encrypted_hesid!=""
bys 				pupilmatchingrefanonymous: gen N_npdid=_N if pupilmatchingrefanonymous!=""
bys 				encrypted_hesid: gen N_hesid=_N if encrypted_hesid!=""
lab	var				N_npdid "Total number of records with this pupil ID" 
lab	var				N_hesid "Total number of records with this HES ID"
tab 				N_npdid, m
tab 				N_hesid , m
*create variables that indicate how often a given match (npd and HES ID) occurs
bys 				pupilmatchingrefanonymous encrypted_hesid: gen n_match=_n if pupilmatchingrefanonymous!="" & encrypted_hesid!=""
lab	var				n_match "record id within this pupilref and HES ID combination"
bys 				pupilmatchingrefanonymous encrypted_hesid: gen N_match=_N if pupilmatchingrefanonymous!="" & encrypted_hesid!=""
lab	var				N_match "Total number of records with this pupilref and HES ID combination"
*extract year of match and matchstep from pds_matchstep and create two separate variables
replace 			pds_matchstep=89999 if pds_matchstep==80
replace 			pds_matchstep=79999 if pds_matchstep==70
gen 				step_pds_matchstep=int(pds_matchstep/10000) 
gen 				year_pds_matchstep=pds_matchstep-int(pds_matchstep/10000)*10000
replace				pds_matchstep = step_pds_matchstep
drop				step_pds_matchstep
label var 			pds_matchstep "Step Linkage Stage 1"
label var 			year_pds_matchstep "Year Linkage Stage 1"
label var 			hes_matchstep "Step Linkage Stage 2"
*label linkage steps
lab def				pdssteplb 	1 "(1) first name: exact, surname: exact, dob: exact, sex: exact, postcode: exact"  ///
								2 "(2) first name: soundex, surname: soundex, dob: exact, sex: exact, postcode: exact"  ///
								3 "(3) first name: 1st char, surname: char 1-3, dob: exact, sex: exact, postcode: exact"  ///
								4 "(4) first name: 1st char, surname: char 1-3, dob: exact, sex: any, postcode: exact"  ///
								5 "(5) first name: any, surname: any, dob: exact, sex: exact, postcode: exact"  ///
								6 "(6) first name: any, surname: any, dob: partial, sex: exact, postcode: exact"  ///
								7 "(7) first name: exact, surname: exact, dob: exact, sex: exact, postcode: any"  ///
								8 "(8) first name: 1st char, surname: char 1-3, dob: exact, sex: exact, postcode: any"
label 				val pds_matchstep pdssteplb
lab def				hessteplb 	1 "(1) NHS number: exact, dob: exact, sex: exact, postcode: exact"  ///
								2 "(2) NHS number: exact, dob: exact, sex: exact, postcode: any"  ///
								3 "(3) NHS number: exact, dob: partial, sex: exact, postcode: exact"  ///
								4 "(4) NHS number: exact, dob: partial, sex: exact, postcode: any"  ///
								5 "(5) NHS number: exact, dob: any, sex: any, postcode: exact"  ///
								6 "(6) NHS number: does not contradict match, dob: exact but not Jan 1st, sex: exact, postcode: exact"  ///
								7 "(7) NHS number: any, dob: exact but not Jan 1st, sex: exact, postcode: exact"  
label 				val hes_matchstep hessteplb
gen					exactlink = 0
replace				exactlink = 1 if pds_matchstep ==1 & pds_matchstep==1
tab					exactlink // 65% have an exact link
gen					link_certainty = string(pds_matchstep) + "." + string(hes_matchstep)
label				var link_certainty "pds matchstep.hes matchstep, lower number = better match"
label				var ae "hes: a&e module"
label				var op "hes: outpatients module"
label				var apc "hes: admitted patient care module"
label				var deaths "hes: mortality module"
label				var plasc "npd: census"
label				var eyc "npd: early years census"
label				var eyfsp "npd: early years foundation stage profile"
label				var pru "npd: pupil referral unit"
label				var ap "npd: alternative provision"
label				var nccis "npd: national client case load information"
label				var ks2 "npd: key stage 2"
label				var ks4 "npd: key stage 4"
label				var ks5 "npd: key stage 5"
merge				m:m pupilmatchingrefanonymous using "${datadir_max}\npd modules\ECHILD_aPMR_and_hesID_plasc.dta", keepusing(summer spring autumn) nogen
sort				pupilmatchingrefanonymous encrypted_hesid link_status pds_matchstep hes_matchstep year_pds_matchstep n_match
order				pupilmatchingrefanonymous encrypted_hesid link_status pds_matchstep hes_matchstep year_pds_matchstep n_match
save 				"${datadir_max}\ECHILD_aPMR_and_hesID_linkstatus.dta", replace
* Note that the numbers could change because a hes number could be duplicated with different cohort numbers
* Table 1
estpost  tabulate  link_status
esttab using "${resultsdir}\linkstatus_and_linkagesteps", cells("b(fmt(%10.0fc) label(count)) pct(fmt(2) label(%)) cumpct(fmt(2) label(cum. %))") ///
varlabels(`e(labels)', blist(Total)) varwidth(20) eqlabels(, lhs("")) nonumber noobs csv ///
title(Table 1. Summary linkage steps (all pairs)) append addnotes("") plain 
* Table 2
estpost  tabulate  link_status if n_npdid==1
esttab using "${resultsdir}\linkstatus_and_linkagesteps", cells("b(fmt(%10.0fc) label(count)) pct(fmt(2) label(%)) cumpct(fmt(2) label(cum. %))") ///
varlabels(`e(labels)', blist(Total)) varwidth(20) eqlabels(, lhs("")) nonumber noobs csv ///
title(Table 2. Summary linkage steps (unique NPDIDs)) append addnotes("") plain
* Table 3
estpost  tabulate  pds_matchstep if n_npdid==1
esttab using "${resultsdir}\linkstatus_and_linkagesteps", cells("b(fmt(%10.0fc) label(count)) pct(fmt(2) label(%)) cumpct(fmt(2) label(cum. %))") ///
varlabels(`e(labels)', blist(Total)) varwidth(20) eqlabels(, lhs("")) nonumber noobs csv ///
title(Table 3. PDS linkage step (unique NPDIDs)) append addnotes("") plain
* Table 4
estpost  tabulate  year_pds_matchstep if n_npdid==1
esttab using "${resultsdir}\linkstatus_and_linkagesteps", cells("b(fmt(%10.0fc) label(count)) pct(fmt(2) label(%)) cumpct(fmt(2) label(cum. %))") ///
varlabels(`e(labels)', blist(Total)) varwidth(20) eqlabels(, lhs("")) nonumber noobs csv ///
title(Table 4. Year PDS linkage steps (unique NPDIDs)) append addnotes("") plain
* Table 5
estpost  tabulate  pds_matchstep 
esttab using "${resultsdir}\linkstatus_and_linkagesteps", cells("b(fmt(%10.0fc) label(count)) pct(fmt(2) label(%)) cumpct(fmt(2) label(cum. %))") ///
varlabels(`e(labels)', blist(Total)) varwidth(20) eqlabels(, lhs("")) nonumber noobs csv ///
title(Table 5. Year PDS linkage steps (all pairs)) append addnotes("") plain
* Table 6
estpost  tabulate  year_pds_matchstep 
esttab using "${resultsdir}\linkstatus_and_linkagesteps", cells("b(fmt(%10.0fc) label(count)) pct(fmt(2) label(%)) cumpct(fmt(2) label(cum. %))") ///
varlabels(`e(labels)', blist(Total)) varwidth(20) eqlabels(, lhs("")) nonumber noobs csv ///
title(Table 6. Year PDS linkage steps (all pairs)) append addnotes("") plain
* Table 7
estpost  tabulate  hes_matchstep  if n_npdid==1
esttab using "${resultsdir}\linkstatus_and_linkagesteps", cells("b(fmt(%10.0fc) label(count)) pct(fmt(2) label(%)) cumpct(fmt(2) label(cum. %))") ///
varlabels(`e(labels)', blist(Total)) varwidth(20) eqlabels(, lhs("")) nonumber noobs csv ///
title(Table 7. Hes linkage steps (unique NPD ID)) append addnotes("") plain
* Table 8
estpost  tabulate  link_certainty   if n_npdid==1
esttab using "${resultsdir}\linkstatus_and_linkagesteps", cells("b(fmt(%10.0fc) label(count)) pct(fmt(2) label(%)) cumpct(fmt(2) label(cum. %))") ///
varlabels(`e(labels)', blist(Total)) varwidth(20) eqlabels(, lhs("")) nonumber noobs csv ///
title(Table 8. Overall link certainty (unique NPD ID)) append addnotes("") plain
*===============================================================================
timer				off 1
timer 				list 1
display as input	"duration of Assign_link_status: " round(r(t1) / 60) " minutes"
timer 				clear 
log 				close