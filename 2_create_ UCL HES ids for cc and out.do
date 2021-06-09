clear
*set directory and pathways
qui do 				"S:\ECHILD_HES\Working\Max\projectLinkageEvaluationAllYears\do\0_global project filepaths.do"
*start log
cap 				log close
log 				using "${logdir}\import_UCL_HES_IDS_$S_DATE.log", replace 
timer				clear
timer				on 1
/*==============================================================================
Project: 			ECHILD - Max Verfuerden
Purpose: 			creates HES ID list for critical care and outpatient data
					filepaths can be checked / changed by looking at the following do-file:
					"S:\ECHILD_HES\Working\Max\projectLinkageEvaluationAllYears\do\0-globaldirectories.do" 
Author: 			maximiliane verfuerden
Created:			Thu 29 Apr 2021
Last run:			Thu 29 Apr 2021
===============================================================================*/
*Import all outpatient files 
foreach    			birthyear in data95_00 data00_07 data07_13 data13_20 {
cd 					"${`birthyear'}"
local 				myfilelist : dir . files "*op*.csv"
di 					`myfilelist'
foreach file of local myfilelist{
*di "`file'"
local 				name= substr(" `file'", 1, length("`file'")-3)
di 					"`name'"
import 				delimited "`file'", encoding(ISO-8859-2) clear
keep				encrypted_hesid *dob*
duplicates			drop
save 				"${hes_notappended_max}\hes_op_`name'.dta", replace 
}
}
timer				off 1
timer 				list 1
display as input	"duration of this do-file: " round(r(t1) / 60) " minutes"
timer 				clear 


/*

*Import all OP files in the 00-07 folder 
cd "${data00_07}"
local myfilelist : dir . files "*op*.csv"
di `myfilelist'
foreach file of local myfilelist{
*di "`file'"
local name= substr(" `file'", 1, length("`file'")-3)
di "`name'"
import delimited "`file'", encoding(ISO-8859-2) clear
save "${hesdata_max}\hes_`name'.dta", replace 
}
local myfilelist : dir . files "*op*.csv"
di `myfilelist'
foreach file of local myfilelist {
di "`file'"
local name= substr(" `file'", 1, length("`file'")-3)
di "`name'"
local name2= substr("`name'", 2, length("`name'")-1)
di "`name2'"
use "${hesdata_max}\hes_`name'.dta", clear 
save "${hesdata_max}\hes_`name2'.dta", replace
erase "${hesdata_max}\hes_`name'.dta"
}
* Import all OP files in the 07-13 folder 
cd "${data07_13}"
local myfilelist : dir . files "*op*.csv"
di `myfilelist'
foreach file of local myfilelist{
*di "`file'"
local name= substr(" `file'", 1, length("`file'")-3)
di "`name'"
import delimited "`file'", encoding(ISO-8859-2) clear
save "${hesdata_max}\hes_`name'.dta", replace 
}
local myfilelist : dir . files "*op*.csv"
di `myfilelist'
foreach file of local myfilelist {
di "`file'"
local name= substr(" `file'", 1, length("`file'")-3)
di "`name'"
local name2= substr("`name'", 2, length("`name'")-1)
di "`name2'"
use "${hesdata_max}\hes_`name'.dta", clear 
save "${hesdata_max}\hes_`name2'.dta", replace
erase "${hesdata_max}\hes_`name'.dta"
}
* Import all OP files in the 13-20 folder 
cd "${data13_20}"
local myfilelist : dir . files "*op*.csv"
di `myfilelist'
foreach file of local myfilelist{
*di "`file'"
local name= substr(" `file'", 1, length("`file'")-3)
di "`name'"
import delimited "`file'", encoding(ISO-8859-2) clear
save "${working_folder}\hes_`name'.dta", replace 
}
local myfilelist : dir . files "*op*.csv"
di `myfilelist'
foreach file of local myfilelist {
di "`file'"
local name= substr(" `file'", 1, length("`file'")-3)
di "`name'"
local name2= substr("`name'", 2, length("`name'")-1)
di "`name2'"
use "${hesdata_max}\hes_`name'.dta", clear 
save "${hesdata_max}\hes_`name2'.dta", replace
erase "${hesdata_max}\hes_`name'.dta"
}
*/

* Identify all files to be prepared
cd "${hesdata_max}"
local myfilelist : dir . files "*op*.dta"
*di `myfilelist'
foreach file of local myfilelist{
use "`file'", clear
count
codebook encrypted_hesid
duplicates drop
count
codebook encrypted_hesid
save "${hesdata_max}hes_`file'_dedup", replace 
}
*===============================================================================
timer				off 1
timer 				list 1
display as input	"duration of this do-file: " round(r(t1) / 60) " minutes"
timer 				clear 