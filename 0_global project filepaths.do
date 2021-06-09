/*==============================================================================
Project: 	ECHILD
Purpose: 	sets file paths
Author: 	maximiliane verfuerden
Created:	09 Apr 2021
===============================================================================*/
clear
cd 			"S:\ECHILD_HES\Working\Max\projectLinkageEvaluationAllYears"
** creating shortcuts for directories *
global 		projectdir "S:\ECHILD_HES\Working\Max\projectLinkageEvaluationAllYears"
global 		datadir_max "$projectdir\data"
global 		hesdata_max "$projectdir\data\HES data"
global 		hes_modulebycohort_max "$projectdir\data\HES data\hes modules by cohort"
global 		hes_idsbymodule_max "$projectdir\data\HES data\distinct hes ids in each module"
global 		npdfiles_max "$projectdir\data\npd modules"
global 		aedata_max "$projectdir\data\HES data\ae"
global 		echild_datadir "S:\ECHILD_HES\Data"
global 		dodir "$projectdir\do"
global 		resultsdir "$projectdir\results"
global 		logdir "$projectdir\log"
global		hes_temp  "$projectdir\data\HES data\temp files"
global		hesextracts "S:\ECHILD_HES\Extracts\ECHILD_HES"
global 		data95_00 "S:\ECHILD_HES\Extracts\ECHILD_HES\Born Sep 1995 to Aug 2000"
global 		data00_07 "S:\ECHILD_HES\Extracts\ECHILD_HES\Born Sep 2000 to Aug 2007"
global 		data07_13 "S:\ECHILD_HES\Extracts\ECHILD_HES\Born Sep 2007 to Aug 2013"
global 		data13_20 "S:\ECHILD_HES\Extracts\ECHILD_HES\Born Sep 2013 to Mar 2020"
**define programs
// create programs that can measure duration of each loop (this is for specific loops in the import UCL HES ids do-file)
cap program			drop timeloop1 timeloop2 timeloop3
program				define timeloop1
timer				off 2
timer 				list 2
display as input	"duration of looping through this hes year: " round(r(t2) / 60) " minute(s)" // t2 because t1 is the one I set at the beginning of the do-file
timer 				clear 2
timer 				on 2
end
program				define timeloop2
timer				off 3
timer 				list 3
display as input	"duration of looping through this birthcohort: " round(r(t3) / 60) " minute(s)"
timer 				clear 3
timer 				on 3
end
program				define timeloop3
timer				off 4
timer 				list 4
display as input	"duration of looping through this hes module: " round(r(t4) / 60) " minute(s)"
timer 				clear 4
timer 				on 4
end

*ados
cap qui		do "S:\Head_or_Heart\max\attributes\7-ado\dropmiss.ado"