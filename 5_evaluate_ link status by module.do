clear
qui do 				"S:\ECHILD_HES\Working\Max\projectLinkageEvaluationAllYears\do\0_global project filepaths.do"
cap 				log close
log 				using "${logdir}\link_status_by_module_$S_DATE.log", replace 
timer				clear
timer				on 1
/*==============================================================================
Project: 			ECHILD - Max Verfuerden
Purpose: 			Show numbers to create a figure displaying link status by module
Created:			22 Apr 2021
Last run:			Thu 6 May 2021
					Fri 21 May 2021
Edit log:			Mon 26 Apr 2021
					Thu 6 May 2021
					Mon 17 May 2021 - add linkstatus by who linked to spring census		
					Wed 2 Jun 2021 - unique APMRs that linked to spring census
===============================================================================*/
use 				"${datadir_max}\ECHILD_aPMR_and_hesID_linkstatus.dta", clear
order				pupilmatchingrefanonymous n_npdid
sort				pupilmatchingrefanonymous n_npdid
********************
*out of all modules (links and non-links), what is the number of unique APMRs by spring_link status?
*(this is important because usually linkage is only based on the spring census)
*link_status==5 means only links to HES but there is no pupil record
********************
foreach				npdmodule of varlist ap-pru {
display	as text		"`npdmodule'"
tab					spring `npdmodule' if `npdmodule'==1 & n_npdid==1 & link_status!=5
}
tab					spring if n_npdid==1 & link_status!=5
tab					spring summer  if summer==1 & n_npdid==1 & link_status!=5
tab					spring autumn  if autumn==1 & n_npdid==1 & link_status!=5
********************
*out of all unique links to UCL HES who links to each module, by spring_link status?
*(this is important because usually linkage is only based on the spring census)
*linkstatus=1 means it links to UCL HES
*by HES year in first instance
********************
levelsof			cohort, local(cohortyear)  
foreach				l of local cohortyear {
foreach				npdmodule of varlist ap-pru {
display	as text		"`npdmodule'"
display	as text		"cohort=`l'"
tab					spring `npdmodule' if `npdmodule'==1 & n_npdid==1 & link_status==1 & cohort==`l'
}
tab					spring summer  if summer==1 & n_npdid==1 & link_status==1  & cohort==`l'
tab					spring autumn  if autumn==1 & n_npdid==1 & link_status==1  & cohort==`l'
}
********************
*for overall UCL HES
********************
foreach				var of varlist ap-pru {
tab					link_status `var' if `var'==1 & n_npdid==1
}
tab					link_status plasc if plasc==1 & spring==1 & n_npdid==1
tab					link_status plasc if plasc==1 & summer==1 & n_npdid==1
tab					link_status plasc if plasc==1 & autumn==1 & n_npdid==1
********************
* by UCL hes module
********************
*show me the ones that linked to UCL HES by NPD module and UCL HES module:
preserve
keep if				n_npdid==1 & link_status==1
foreach				hesmodule of varlist ae-deaths {
foreach				npdmodule of varlist spring summer autumn ap-pru  {
display	as text		"`hesmodule' and `npdmodule'"
tab					`hesmodule'  `npdmodule', m
}
}
restore
*show me the the how many are in each NPD module by link status:
preserve
keep if				n_npdid==1 
foreach				npdmodule of varlist ap-pru {
foreach				hesmodule of varlist ae-deaths {
display	as text		"`hesmodule'"
display	as text		"`npdmodule'"
tab					link_status `npdmodule' if `npdmodule'==1 & `hesmodule' ==1
}
}
foreach				hesmodule of varlist ae-deaths {
tab					link_status `hesmodule', m
}
foreach				npdmodule of varlist ap-pru spring summer autumn {
tab					link_status `npdmodule', m
}
restore
********************
*for the censuses (spring, summer, autumn)
********************
foreach				hesmodule of varlist ae-deaths {
display	as text		"`hesmodule' for plasc spring"
tab					link_status plasc if plasc==1 & spring==1 & n_npdid==1 & `hesmodule' ==1
display	as text		"`hesmodule' for plasc summer"
tab					link_status plasc if plasc==1 & summer==1 & n_npdid==1 & `hesmodule' ==1
display	as text		"`hesmodule' for plasc autumn"
tab					link_status plasc if plasc==1 & autumn==1 & n_npdid==1 & `hesmodule' ==1
}
foreach				npdmodule of varlist ap-pru {
display	as text		"`npdmodule' for plasc spring"
tab					link_status plasc if plasc==1 & spring==1 & n_npdid==1
display	as text		"`npdmodule' for plasc summer"
tab					link_status plasc if plasc==1 & summer==1 & n_npdid==1 
display	as text		"`npdmodule' for plasc autumn"
tab					link_status plasc if plasc==1 & autumn==1 & n_npdid==1 
}	
*===============================================================================
timer				off 1
timer 				list 1
display as input	"duration of this do-file: " round(r(t1) / 60) " minutes"
timer 				clear 
log 				close