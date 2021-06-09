clear
qui do 				"S:\ECHILD_HES\Working\Max\projectLinkageEvaluationAllYears\do\0_global project filepaths.do"
cap 				log close
log 				using "${logdir}\clean_UCL_HES_IDS_$S_DATE.log", replace 
timer				clear
timer				on 1 // start timer for whole do-file
/*==============================================================================
Project: 			ECHILD - Max Verfuerden (my goal is to evaluate linkage)
Purpose: 			adds age at first link to the UCL HES modules
					encrypted hesid, birth cohort, module and hes year
Author: 			maximiliane verfuerden
Created:			Tue 04 May 2021
Last modified:		
Last run:			
***
technical notes:    
					-filepaths can be checked / changed by looking at the following do-file:
					"S:\ECHILD_HES\Working\Max\projectLinkageEvaluationAllYears\do\0-globaldirectories.do" 
===============================================================================*/
*open merged dataset and 

*===============================================================================
timer				off 1 
timer 				list 1 
display as input	"duration of this do-file: " round(r(t1) / 60) " minutes"
timer 				clear 