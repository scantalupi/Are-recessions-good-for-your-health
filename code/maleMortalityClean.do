*************************************
*************************************
*** This do file provides the code to clean and create a dataset containing 
*** mortality rate (total and by cause) for males and for age class
*** unemploymnet rate, activity rate 
*************************************
*************************************
clear all 
set more off
cap log close

global datapath  "/Users/simonecantalupi/Desktop/Thesis/thesis_Cantalupi_0001092400/replicationStata/data/raw"

global projectpath "/Users/simonecantalupi/Desktop/Thesis/thesis_Cantalupi_0001092400/replicationStata"

*************************
*** UNEMPLOYMENT RATE ***
*************************
clear all 

*** Import the original dataset about the disoccupation rate in csv format ***
import delimited "$datapath/DCCV_TAXDISOCCU1_UNT2020_30012024092317131.csv"

* Keep observations for both sexes combined
keep if strpos(sesso, "maschi")

* Drop observations for the years outside 2005-2020, destring it and label it
* (this to have four age classes)
drop if strpos(time, "Q")
 
destring time, replace

keep if 2005 <= time & time <=2019

rename time year 
label var year "Year"

* Create a numeric variable for all the region 
rename territorio region
label var region "Region"

egen region_numeric = group(region), label	 


* Create a numeric variable for the age classes of interests
keep if strpos(classedietà, "15-24 anni") | strpos(classedietà, "25-34 anni") |strpos(classedietà, "35-44 anni") | strpos(classedietà, "45-54 anni") | strpos(classedietà, "55-64 anni") 

gen numeric_eta1 = real(regexs(1)) if regexm(classedietà, "(\d+)-(\d+) anni")

gen age_category = . 

replace age_category = 1 if numeric_eta1 >= 15 & numeric_eta1 <= 24
replace age_category = 2 if numeric_eta1 >= 25 & numeric_eta1 <= 34
replace age_category = 3 if numeric_eta1 >= 35 & numeric_eta1 <= 44
replace age_category = 4 if numeric_eta1 >= 45 & numeric_eta1 <= 54
replace age_category = 5 if numeric_eta1 >= 55 & numeric_eta1 <= 64

*** Sort dataset ***
sort year region_numeric age_category sex

* Generate a unique identifier variable
gen AID = _n

*** Rename and add lables to some varibales ***
rename sexistat1 sex
destring sex, replace 

rename value unemployment_rate
label var unemployment_rate "Unemployment rate"

*** Save the cleaned dataset ***
keep AID age_category sex year region region_numeric unemployment_rate

save "$projectpath/data/raw/clean/maleUnemploymentRate.dta", replace 


br

**********************
*** MORTALITY RATE ***
**********************
clear all 

*** Import the original dataset about mortality in csv format ***
import delimited "$datapath/DCIS_CMORTE1_EV_30012024110635630.csv"

* Keep observations for males only
rename sesso sex
label var sex "Sex"

keep if strpos(sex, "maschi")

* Rename variable time 
rename time year
label var year "Year"

drop if year <= 2004

* Rename variable age 
rename età age 
label var age 

* Rename variable cause 
rename causainizialedimorteeuropeanshor cause 
label var cause "Cause of death"

* Keep only the observations for total death 
keep if strpos(cause, "total")

* Create a numeric variable for all the region 
rename territorio region
label var region "Region"

egen region_numeric = group(region), label

* Keep observations for only specific ages 
drop if strpos(age, "-")

* Create age classes and sum the deaths value for each year
gen age_numeric = real(regexs(1)) if regexm(eta1, "Y(\d+)")

gen age_category = . 
replace age_category = 1 if age_numeric >= 15 & age_numeric <= 24
replace age_category = 2 if age_numeric >= 25 & age_numeric <= 34
replace age_category = 3 if age_numeric >= 35 & age_numeric <= 44
replace age_category = 4 if age_numeric >= 45 & age_numeric <= 54
replace age_category = 5 if age_numeric >= 55 & age_numeric <= 64

* Generate a variable that takes the sum of all deaths count
egen deaths = total(value) if !missing(age_category), by(year region_numeric age_category)

* Keep only one observation for each age class
keep if age_numeric == 15 | age_numeric == 25 | age_numeric == 35 | age_numeric == 45 | age_numeric == 55 

*** Sort dataset ***
sort year region_numeric age_category sex

* Generate a unique identifier variable
gen AID = _n

*** Save the cleaned dataset ***
keep AID age_category sex year region region_numeric deaths 

br

save "$projectpath/data/raw/clean/maleDeaths.dta", replace 


*** Merge the dataset with the population dataset to obtain the death rate ***
clear all

* Clean the dataset 
import delimited "$datapath/DCIS_RICPOPRES2011_01022024092337849.csv"

* Keep observations for males only
rename sesso sex
label var sex "Sex"

keep if strpos(sex, "maschi")

* Rename variable time 
rename time year
label var year "Year"

drop if year <= 2004

* Rename variable age 
rename eta1 age 
label var age 

* Create a numeric variable for all the region 
rename territorio region
label var region "Region"

drop if strpos(region, "Italia")

egen region_numeric = group(region), label

* Create age classes and sum the deaths value for each year
gen age_numeric = real(regexs(1)) if regexm(age, "Y(\d+)")

gen age_category = . 
replace age_category = 1 if age_numeric >= 15 & age_numeric <= 24
replace age_category = 2 if age_numeric >= 25 & age_numeric <= 34
replace age_category = 3 if age_numeric >= 35 & age_numeric <= 44
replace age_category = 4 if age_numeric >= 45 & age_numeric <= 54
replace age_category = 5 if age_numeric >= 55 & age_numeric <= 64

* Generate a variable that takes the sum of all deaths count
egen population = total(value) if !missing(age_category), by(year region_numeric age_category)

* Keep only one observation for each age class
keep if age_numeric == 15 | age_numeric == 25 | age_numeric == 35 | age_numeric == 45 | age_numeric == 55 

*** Sort dataset ***
sort year region_numeric age_category sex

* Generate a unique identifier variable
gen AID = _n

*** Save the cleaned dataset ***
keep AID age_category sex year region region_numeric population

save "$projectpath/data/raw/clean/populationMale.dta", replace 

* Merge the datasets 
clear all

use "$datapath/clean/maleDeaths.dta"

merge m:1 AID using "$datapath/clean/populationMale.dta"

* Calculate death rate per 1,000 males
gen death_rate = (deaths / population) * 1000
label var death_rate "All Causes Male Mortality Rate"

* Save the dataset 
save "$projectpath/data/raw/clean/maleDeathRate.dta", replace 





*************************************
*** CAUSE SPECIFIC MORTALITY RATE ***
*************************************
clear all 

*** Import the original dataset about the mortality in csv format ***
import delimited "$datapath/DCIS_CMORTE1_EV_01022024090856120.csv"

* Keep observations for males only
rename sesso sex
label var sex "Sex"

keep if strpos(sex, "maschi")

* Rename variable time 
rename time year
label var year "Year"

keep if year >= 2005 & year <= 2019

* Rename variable age 
rename età age 
label var age 

* Rename variable cause 
rename causainizialedimorteeuropeanshor cause 
label var cause "Cause of death"

* Discard the observations for total death 
drop if strpos(cause, "total")

* Create age classes and sum the deaths value for each year
gen age_numeric = real(regexs(1)) if regexm(age, "-(\d+)")

gen age_category = . 
replace age_category = 1 if age_numeric >= 15 & age_numeric <= 24
replace age_category = 2 if age_numeric >= 25 & age_numeric <= 34
replace age_category = 3 if age_numeric >= 35 & age_numeric <= 44
replace age_category = 4 if age_numeric >= 45 & age_numeric <= 54
replace age_category = 5 if age_numeric >= 55 & age_numeric <= 64

* Create a numeric variable for all the region 
rename territorio region
label var region "Region"

egen region_numeric = group(region), label	

* Keep only the causes of death needed
keep if strpos(cause, "tumori maligni") | ///
        strpos(cause, "malattie ischemiche del cuore") | ///
		strpos(cause, "malattie cerebrovascolari") | ///
		strpos(cause, "altre malattie del cuore") | ///
		strpos(cause, "malattie dell'apparato digerente") | ///
		strpos(cause, "di cui accidenti di trasporto") | ///
		strpos(cause, "suicidio e autolesione intenzionale") | ///
		strpos(cause, "tumori non maligni (benigni e di comportamento incerto)") | ///
		strpos(cause, "di cui tumori maligni della trachea, dei bronchi e dei polmoni") | ///
		strpos(cause, "di cui tumori maligni del colon, del retto e dell'ano") | ///
		strpos(cause, "altre malattie infettive e parassitarie")
			
		
* Generate varibales for each of the eight cause-specific deaths
egen malignant_tumors = total(value) if !missing(age_category) ///
     & cause == "tumori maligni", ///
	 by(year region_numeric age_category)

egen ischameic_hearth = total(value) if !missing(age_category) ///
     & cause == "malattie ischemiche del cuore", ///
	 by(year region_numeric age_category)

egen cerebrovascular = total(value) if !missing(age_category) ///
     & cause == "malattie cerebrovascolari", ///
	 by(year region_numeric age_category) 

egen other_hearth = total(value) if !missing(age_category) ///
     & cause == "altre malattie del cuore", ///
	 by(year region_numeric age_category)

egen digestive_system = total(value) if !missing(age_category) ///
     & cause == "malattie dell'apparato digerente", ///
	 by(year region_numeric age_category)

egen transportation_accidents = total(value) if !missing(age_category) ///
     & cause == "di cui accidenti di trasporto", ///
	 by(year region_numeric age_category) 

egen sucidie = total(value) if !missing(age_category) ///
     & cause == "suicidio e autolesione intenzionale", ///
	 by(year region_numeric age_category)

egen nonmalignant_tumors = total(value) if !missing(age_category) ///
     & cause == "tumori non maligni (benigni e di comportamento incerto)", ///
	 by(year region_numeric age_category)

egen h_c_amenable = total(value) if !missing(age_category) ///
     & cause == "di cui tumori maligni della trachea, dei bronchi e dei polmoni" | cause == "malattie ischemiche del cuore" | cause == "malattie cerebrovascolari" | cause == "di cui tumori maligni del colon, del retto e dell'ano" | cause =="diabete mellito" | cause == "altre malattie infettive e parassitarie", ///
	 by(year region_numeric age_category) 

	 
* Keep one observation for each age category
keep if age_numeric == 19 | age_numeric == 29 | age_numeric == 39 | age_numeric == 49 | age_numeric == 59 

* Collapse the dataset 
collapse (sum) malignant_tumors ischameic_hearth cerebrovascular other_hearth digestive_system transportation_accidents sucidie nonmalignant_tumors h_c_amenable, by(year region_numeric age_category)

*** Sort dataset ***
sort year region_numeric age_category 

* Generate a unique identifier variable
gen AID = _n

*** Save the cleaned dataset ***
keep AID age_category year region region_numeric malignant_tumors ///
     ischameic_hearth cerebrovascular other_hearth digestive_system ///
	 transportation_accidents sucidie nonmalignant_tumors h_c_amenable

br	 
	 	 
save "$projectpath/data/raw/clean/maleDeathsSpecific.dta", replace 



*** Calculate the rate for specific causes of deaths ***
clear all 

*** Build a dataset to obtain the values of all type of deaths for each age category ***
use "$datapath/clean/maleDeaths.dta", clear

* Merge the two datasets
use "$datapath/clean/maleDeathsSpecific.dta"

merge m:1 AID using "$datapath/clean/populationMale.dta"

* Generate the rates for each specific cause of death
gen malignant_tumors_rate = (malignant_tumors / population) * 1000 
label var malignant_tumors_rate "Malignant Tumors Male Death Rate"

gen ischameic_hearth_rate = (ischameic_hearth / population) * 1000
label var ischameic_hearth_rate "Ischameic Hearth Diseases Male Death Rate"

gen cerebrovascular_rate = (cerebrovascular / population) * 1000
label var cerebrovascular_rate "Cerebrovascular Diseases Male Death Rate"

gen other_hearth_rate = (other_hearth / population) * 1000
label var other_hearth_rate "Other Hearth Diseases Male Death Rate"

gen digestive_system_rate = (digestive_system / population) * 1000
label var digestive_system_rate "Digestive System Diseases Male Death Rate"

gen transportation_accidents_rate = (transportation_accidents / population) * 1000
label var transportation_accidents_rate "Transportation Accidents Male Death Rate"

gen sucidie_rate = (sucidie / population) * 1000
label var sucidie_rate "Sucidie Male Rate"

gen nonmalignant_tumors_rate = (nonmalignant_tumors / population) * 1000 
label var nonmalignant_tumors_rate "Malignant Tumors Male Death Rate"

gen h_c_amenable_rate = (h_c_amenable / population) * 1000
label var h_c_amenable_rate "Health-Care-Amenable Male Death Rate"

*** Save the dataset ***
keep AID age_category year region region_numeric malignant_tumors_rate ///
     ischameic_hearth_rate cerebrovascular_rate other_hearth_rate ///
	 digestive_system_rate transportation_accidents_rate ///
	 sucidie_rate nonmalignant_tumors_rate h_c_amenable_rate


save "$projectpath/data/raw/clean/maleDeathsSpecificRate.dta", replace




*********************
*** ACTIVITY RATE ***
*********************
clear all

* Import the dataset of the gross domestic product, production side 
import delimited "$datapath/DCCV_TAXATVT1_UNT2020_06022024105629368.csv"

* Rename variables 
rename value activity_rate
label var activity_rate "Activty Rate"

* Keep observations for males only
rename sesso sex
label var sex "Sex"

keep if strpos(sex, "maschi") 

* Select the time frame 
rename time year
label var year "Year"

drop if strpos(year, "Q")  
destring year, replace 

keep if year >= 2005 & year <= 2019

* Create a numeric variable for all the region 
rename territorio region
label var region "Region"

drop if strpos(region, "Italia")

egen region_numeric = group(region), label

* Rename variable age 
rename eta1 age 
label var age 

* Create age classes and sum the deaths value for each year
gen age_numeric = real(regexs(1)) if regexm(age, "-(\d+)")

tab age

sort year region 
br

gen age_category = . 
replace age_category = 1 if age_numeric >= 15 & age_numeric <= 24
replace age_category = 2 if age_numeric >= 25 & age_numeric <= 34
replace age_category = 3 if age_numeric >= 35 & age_numeric <= 44
replace age_category = 4 if age_numeric >= 45 & age_numeric <= 54
replace age_category = 5 if age_numeric >= 55 & age_numeric <= 64

tab age_category

*** Sort dataset ***
sort year region_numeric age_category 

* Generate a unique identifier variable
gen AID = _n

*** Save the cleaned dataset ***
keep AID age_category year region region_numeric activity_rate

br	 
	 
* Save the dataset 
save "$projectpath/data/raw/clean/maleActivtyRate.dta", replace





******************************
*** MERGE ALL THE DATASETS ***
******************************
clear all 

* Load the first dataset
use "$datapath/clean/maleDeathsSpecificRate.dta", clear

* Merge with the second dataset using m:1 and AID as the key variable
merge m:1 AID using "$datapath/clean/maleActivtyRate.dta", nogen

* Save the merged dataset
save "$datapath/clean/merged4.dta", replace


* Load the third dataset
use "$datapath/clean/maleDeathRate.dta", clear

* Merge with the previously merged dataset using m:1 and AID as the key variable
merge m:1 AID using "$datapath/clean/merged4.dta", nogen

* Save the merged dataset
save "$datapath/clean/merged5.dta", replace


* Load the fourth dataset
use "$datapath/clean/maleUnemploymentRate.dta", clear

* Merge with the previously merged dataset using m:1 and AID as the key variable
merge m:1 AID using "$datapath/clean/merged5.dta", nogen force



* Sort the dataset
sort year region_numeric age_category
 
* Drop the not needed variables 
drop sex
drop deaths 
drop population
drop region
drop _merge 
drop AID

* Order the dataset (i.e., change the order of columns)
ds

order year region age_category unemployment_rate activity_rate death_rate

* Save the final merged dataset
save "$datapath/clean/maleFinal.dta", replace

br
