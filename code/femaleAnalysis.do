*************************************
*************************************
*** This do file provides the code to perform the economettic analysis
*** and genetate the tables with the fixed effect estimates for females
*************************************
*************************************
clear all 
set more off
cap log close

global datapath  "/Users/simonecantalupi/Desktop/Thesis/thesis_Cantalupi_0001092400/replicationStata/data/raw"

global projectpath "/Users/simonecantalupi/Desktop/Thesis/thesis_Cantalupi_0001092400/replicationStata"

* Load the needed dataset
use "$datapath/clean/femaleFinal.dta", clear

br 

*** Descriptive statistic
eststo drop *
estpost summarize activity_rate unemployment_rate death_rate ///        
     malignant_tumors_rate ischameic_hearth_rate cerebrovascular_rate ///
	 other_hearth_rate digestive_system_rate transportation_accidents_rate ///
	 sucidie_rate nonmalignant_tumors_rate h_c_amenable_rate

*** Statistical analysis 

* Linear trend regressions
egen cross = group(region_numeric age_category)

xtset cross year

eststo drop *
eststo: xtreg death_rate activity_rate year, vce(cluster cross) fe

eststo: xtreg malignant_tumors_rate activity_rate year, vce(cluster cross) fe

eststo: xtreg ischameic_hearth_rate activity_rate year, vce(cluster cross) fe

eststo: xtreg cerebrovascular_rate activity_rate year, vce(cluster cross) fe

eststo: xtreg other_hearth_rate activity_rate year, vce(cluster cross) fe

eststo: xtreg digestive_system_rate activity_rate year, vce(cluster cross) fe

eststo: xtreg transportation_accidents_rate activity_rate year, vce(cluster cross) fe

eststo: xtreg sucidie_rate activity_rate year, vce(cluster cross) fe

eststo: xtreg nonmalignant_tumors_rate activity_rate year, vce(cluster cross) fe

eststo: xtreg h_c_amenable_rate activity_rate year, vce(cluster cross) fe





*** Tables for appendix ***


* Unemployment Rate *

xtset cross year

eststo drop *
eststo: xtreg death_rate unemployment_rate year, vce(cluster cross) fe

eststo: xtreg malignant_tumors_rate unemployment_rate year, vce(cluster cross) fe

eststo: xtreg ischameic_hearth_rate unemployment_rate year, vce(cluster cross) fe

eststo: xtreg cerebrovascular_rate unemployment_rate year, vce(cluster cross) fe

eststo: xtreg other_hearth_rate unemployment_rate year, vce(cluster cross) fe

eststo: xtreg digestive_system_rate unemployment_rate year, vce(cluster cross) fe

eststo: xtreg transportation_accidents_rate unemployment_rate year, vce(cluster cross) fe

eststo: xtreg sucidie_rate unemployment_rate year, vce(cluster cross) fe

eststo: xtreg nonmalignant_tumors_rate unemployment_rate year, vce(cluster cross) fe

eststo: xtreg h_c_amenable_rate unemployment_rate year, vce(cluster cross) fe



*************************
*** Robustness checks ***
*************************


** Robustness check 1 - FE regressions **
clear all 

* Re-load the needed dataset
use "$datapath/clean/femaleFinal.dta", clear

egen cross = group(region_numeric age_category)

xtset cross year

eststo drop *
eststo: xtreg death_rate activity_rate i.year, vce(cluster cross) fe

eststo: xtreg malignant_tumors_rate activity_rate i.year, vce(cluster cross) fe

eststo: xtreg ischameic_hearth_rate activity_rate i.year, vce(cluster cross) fe

eststo: xtreg cerebrovascular_rate activity_rate i.year, vce(cluster cross) fe

eststo: xtreg other_hearth_rate activity_rate i.year, vce(cluster cross) fe

eststo: xtreg digestive_system_rate activity_rate i.year, vce(cluster cross) fe

eststo: xtreg transportation_accidents_rate activity_rate i.year, vce(cluster cross) fe

eststo: xtreg sucidie_rate activity_rate i.year, vce(cluster cross) fe

eststo: xtreg nonmalignant_tumors_rate activity_rate i.year, vce(cluster cross) fe

eststo: xtreg h_c_amenable_rate activity_rate i.year, vce(cluster cross) fe



** Robustness check 2 - Individuals aged 25-54 **
clear all 

* Re-load the needed dataset
use "$datapath/clean/femaleFinal.dta", clear

* Consider only individuals aged 25-54

drop if age_category == 1 | age_category == 5

br

* Linear trend regressions
egen cross = group(region_numeric age_category)

xtset cross year

eststo drop *
eststo: xtreg death_rate activity_rate year, vce(cluster cross) fe

eststo: xtreg malignant_tumors_rate activity_rate year, vce(cluster cross) fe

eststo: xtreg ischameic_hearth_rate activity_rate year, vce(cluster cross) fe

eststo: xtreg cerebrovascular_rate activity_rate year, vce(cluster cross) fe

eststo: xtreg other_hearth_rate activity_rate year, vce(cluster cross) fe

eststo: xtreg digestive_system_rate activity_rate year, vce(cluster cross) fe

eststo: xtreg transportation_accidents_rate activity_rate year, vce(cluster cross) fe

eststo: xtreg sucidie_rate activity_rate year, vce(cluster cross) fe

eststo: xtreg nonmalignant_tumors_rate activity_rate year, vce(cluster cross) fe

eststo: xtreg h_c_amenable_rate activity_rate year, vce(cluster cross) fe





** Robustness check 3 - Distinction between young adults and older ones **

** Robustness check 3.1 **
clear all

* Re-load the needed dataset
use "$datapath/clean/femaleFinal.dta", clear

* Select only individuals aged between 15 to 34

keep if age_category == 1 | age_category == 2 


* Linear trend regressions
egen cross = group(region_numeric age_category)

xtset cross year

eststo drop *
eststo: xtreg transportation_accidents_rate activity_rate year, vce(cluster cross) fe

eststo: xtreg h_c_amenable_rate activity_rate year, vce(cluster cross) fe


** Robustness check 3.2 **
clear all

* Re-load the needed dataset
use "$datapath/clean/femaleFinal.dta", clear

* Select only individuals aged between 35 to 54

keep if age_category == 3 | age_category == 4


* Linear trend regressions
egen cross = group(region_numeric age_category)

xtset cross year

eststo drop *
eststo: xtreg transportation_accidents_rate activity_rate year, vce(cluster cross) fe

eststo: xtreg h_c_amenable_rate activity_rate year, vce(cluster cross) fe


