************************************
*** DESCRIPTIVE ANALYSIS - GRAPH ***
*************************************
*************************************
*** This do file provides the code generate a graph that plots 
*** the differences in the trends between male and females 
*** for both deaths rate and unemployment rate
*************************************
*************************************
************************************
clear all 
set more off
cap log close

global datapath  "/Users/simonecantalupi/Desktop/Thesis/thesis_Cantalupi_0001092400/replicationStata/data/raw"

global projectpath "/Users/simonecantalupi/Desktop/Thesis/thesis_Cantalupi_0001092400/replicationStata"

br
******************************************************
*** GRAPH - BOTH SEXES UNEMPLOYMENT AND DEATH RATE ***
******************************************************
clear all 
set more off
cap log close

*******************************************
*** Clean the unemployment rate dataset ***
*******************************************
*** Import the original dataset about the disoccupation rate in csv format ***
import delimited "$datapath/DCCV_TAXDISOCCU1 - Tasso di disoccupazione - intero ds.csv"

*** Clean the dataset ***

* Drop observations for both sexes
keep if strpos(sesso, "totale")

rename sesso sex

* Drop observations for not needed detailed variables
keep if strpos(titolodistudio, "totale")

keep if strpos(v12, "totale")

keep if strpos(duratadelladisoccupazione, "totale")


* Drop observations for the years outside 2005-2020 (but keep 2004 to detrend)
drop if strpos(time, "Q") | strpos(time, "2021") | strpos(time, "2022")
 
destring time, replace

rename time year 
label var year "Year"

* Keep the observations for all regions combined 
keep if strpos(territorio, "Italia") 

rename territorio region 

* Keep the observations for all the total of the age group
keep if strpos(classedietà, "15-64 anni")

rename classedietà age

* Unemployment rate
rename value unemployment_rate

*** Sort the dataset ***
sort year 

drop if year == 2020

*** Generate a unique identifier variable ***
gen AID = _n


*** Save the cleaned dataset ***
keep AID year unemployment_rate 

save "$projectpath/data/raw/clean/allAgesUnemploymentRateTotal.dta", replace 

 

********************************
*** Clean the deaths dataset ***
********************************
clear all

*** Import the original dataset about deaths in csv format ***
import delimited "$datapath/DCIS_MORTALITA1 - Tavole di mortalità - intero ds.csv"

*** Clean the dataset ***
keep if strpos(tipo_dato15, "DEATHS")

keep if strpos(sesso, "totale")

drop if strpos(eta1, "-") > 0

* Keep the observations for all regions combined 
keep if strpos(territorio, "Italia") 

* Drop observations for the years outside 2005-2020 (but keep 2004 to detrend)
keep if 2004 <= time & time <=2020

rename time year 
label var year "Year"

* Keep the observations for the age group 15-64 and sum the deaths value for each year
gen numeric_eta1 = real(regexs(1)) if regexm(eta1, "Y(\d+)")

keep if 15 <= numeric_eta1 & numeric_eta1 <= 64

gen age_category = . 
replace age_category = 1 if numeric_eta1 >= 15 & numeric_eta1 <= 64

egen deaths = total(value) if !missing(age_category), by(year)

label var deaths "Total female deaths (15-64 years old)"

*** Keep only a set of observations for each year ***
keep if strpos(etàeclassidietà, "61 anni") 

*** Sort the dataset ***
sort year

*** Generate a unique identifier variable ***
gen AID = _n


*** Save the cleaned dataset ***
keep AID year deaths 

save "$projectpath/data/raw/clean/allAgesTotalDeaths.dta", replace 



*** Merge the dataset with the population dataset to obtain rate ***
clear all

* Clean the dataset 
import delimited "$datapath/DCIS_RICPOPRES2011_01022024092337849.csv"

* Keep observations for both sexes only
rename sesso sex
label var sex "Sex"

keep if strpos(sex, "totale")

* Rename variable time 
rename time year
label var year "Year"

* Rename variable age 
rename eta1 age 
label var age 

* Create a numeric variable for all the region 
rename territorio region
label var region "Region"

keep if strpos(region, "Italia")

egen region_numeric = group(region), label

* Create age classes and sum the deaths value for each year
gen age_numeric = real(regexs(1)) if regexm(age, "Y(\d+)")

gen age_category = . 
replace age_category = 1 if age_numeric >= 15 & age_numeric <=  64

* Keep only one observation for each age class
keep if age_numeric == 15 

* Generate a variable that takes the sum of all deaths count
egen population = total(value) if !missing(age_category), by(year)

*** Sort dataset ***
sort year region_numeric age_category sex

* Generate a unique identifier variable
gen AID = _n

*** Save the cleaned dataset ***
keep AID age_category sex year region region_numeric population

save "$projectpath/data/raw/clean/allAgesPopulationTotal.dta", replace 

* Merge the datasets 
clear all

use "$datapath/clean/allAgesTotalDeaths.dta"

merge m:1 AID using "$datapath/clean/allAgesPopulationTotal.dta"

*** Calculate death rate per 1,000 individuals 
gen death_rate = (deaths / population) * 1000

drop _merge 

* Save the dataset 
save "$projectpath/data/raw/clean/allAgesTotalDeathRate.dta", replace 




**********************
*** Draw the graph ***
**********************
clear all

*************************
*** Descriptive graph ***
*************************
clear all 

*** Merge the cleaned datasets ***
use "$datapath/clean/allAgesTotalDeathRate.dta"

merge m:1 AID using "$datapath/clean/allAgesUnemploymentRateTotal.dta"

tsset year
sort year

drop if year == 2004

* Draw the graph
* Create line plot with years on the x-axis on the y-axis the standard devaition from the mean 
set scheme s1color

* Specify tick positions with more space between major ticks
local tick_positions 2005(5)2020

* Generate the graph
twoway (scatter unemployment_rate year, connect(l) msymbol(d) ytitle("Rate (%)") lc(blue) mcolor(blue)) || ///
       (scatter death_rate year, connect(l) ytitle("Rate (%)") lc(red) mcolor(red)), ///
       xtitle("Year") xla(`tick_positions') ///
       legend(label(1 "Total Unemployment Rate") label(2 "Total Death Rate") pos(6) col(1) region(fc(white)))


*** Export and save the graph ***
graph export "$projectpath/outputs/Graphs/totalDeathsUnempDescriptiveGraph.png", replace
	   
	   
*************************************
*** Detrended and normalize graph ***
*************************************
clear all 

*** Merge the cleaned datasets ***
use "$datapath/clean/allAgesTotalDeathRate.dta"

merge m:1 AID using "$datapath/clean/allAgesUnemploymentRateTotal.dta"

tsset year
sort year

* Detrend and normalize death rate
gen pct_deaths = death_rate - l.death_rate

egen mean_deaths = mean(pct_deaths)
egen sd_deaths = sd(pct_deaths)

gen norm_pct_deaths = (pct_deaths - mean_deaths) / sd_deaths


* Detrend and normalize unemployment rate
gen pct_ur = unemployment_rate - l.unemployment_rate

egen mean_ur = mean(pct_ur)
egen sd_ur = sd(pct_ur)

gen norm_pct_ur = (pct_ur - mean_ur) / sd_ur

* Create line plot with years on the x-axis on the y-axis the standard devaition from the mean 
set scheme s1color

* Specify tick positions with more space between major ticks
local tick_positions 2005(5)2020

* Generate the graph
twoway (scatter norm_pct_ur year, connect(l) msymbol(d) ytitle("Standard Deviation From Mean") lc(blue) mcolor(blue)) || ///
       (scatter norm_pct_deaths year, connect(l) ytitle("Standard Deviation From Mean") lc(red) mcolor(red)), ///
       xtitle("Year") xla(`tick_positions') ///
       legend(label(1 "Total Unemployment Rate") label(2 "Total Death Rate") pos(6) col(1) region(fc(white)))

*** Export and save the graph ***
graph export "$projectpath/outputs/Graphs/totalDeathsUnempGraph.png", replace









************************************************
*** GRAPH - MALE UNEMPLOYMENT AND DEATH RATE ***
************************************************
clear all 
set more off
cap log close

*******************************************
*** Clean the death rate rate dataset ***
*******************************************
*** Import the original dataset about the disoccupation rate in csv format ***
import delimited "$datapath/DCIS_MORTALITA1 - Tavole di mortalità - intero ds.csv"

*** Clean the dataset ***
keep if strpos(tipo_dato15, "DEATHS")

keep if strpos(sesso, "maschi")

drop if strpos(eta1, "-") > 0

* Keep the observations for all regions combined 
keep if strpos(territorio, "Italia") 

* Drop observations for the years outside 2005-2020 (but keep 2004 to detrend)
keep if 2004 <= time & time <=2020

rename time year 
label var year "Year"

* Keep the observations for the age group 15-64 and sum the deaths value for each year
gen numeric_eta1 = real(regexs(1)) if regexm(eta1, "Y(\d+)")

keep if 15 <= numeric_eta1 & numeric_eta1 <= 64

gen age_category = . 
replace age_category = 1 if numeric_eta1 >= 15 & numeric_eta1 <= 64

egen deaths = total(value) if !missing(age_category), by(year)

label var deaths "Total male deaths (15-64 years old)"

*** Keep only a set of observations for each year ***
keep if strpos(etàeclassidietà, "61 anni") 

*** Sort the dataset ***
sort year

*** Generate a unique identifier variable ***
gen AID = _n


*** Save the cleaned dataset ***
keep AID year deaths 

save "$projectpath/data/raw/clean/allAgesMaleDeaths.dta", replace 



*** Merge the dataset with the population dataset to obtain rate ***
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

* Rename variable age 
rename eta1 age 
label var age 

* Create a numeric variable for all the region 
rename territorio region
label var region "Region"

keep if strpos(region, "Italia")

egen region_numeric = group(region), label

* Create age classes and sum the deaths value for each year
gen age_numeric = real(regexs(1)) if regexm(age, "Y(\d+)")

gen age_category = . 
replace age_category = 1 if age_numeric >= 15 & age_numeric <=  64

* Keep only one observation for each age class
keep if age_numeric == 15 

* Generate a variable that takes the sum of all deaths count
egen population = total(value) if !missing(age_category), by(year)

*** Sort dataset ***
sort year region_numeric age_category sex

* Generate a unique identifier variable
gen AID = _n

*** Save the cleaned dataset ***
keep AID age_category sex year region region_numeric population

save "$projectpath/data/raw/clean/allAgesPopulationMale.dta", replace 



* Merge the datasets 
clear all

use "$datapath/clean/allAgesMaleDeaths.dta"

merge m:1 AID using "$datapath/clean/allAgesPopulationMale.dta"

*** Calculate death rate per 1,000 males
gen death_rate = (deaths / population) * 1000

drop _merge 

* Save the dataset 
save "$projectpath/data/raw/clean/allAgesMaleDeathRate.dta", replace 



*******************************************
*** Clean the unemployment rate dataset ***
*******************************************
clear all 

*** Import the original dataset about the disoccupation rate in csv format ***
import delimited "$datapath/DCCV_TAXDISOCCU1 - Tasso di disoccupazione - intero ds.csv"

*** Clean the dataset ***

* Drop observations for male sex
keep if strpos(sesso, "maschi")

rename sesso sex

* Drop observations for not needed detailed variables
keep if strpos(titolodistudio, "totale")

keep if strpos(v12, "totale")

keep if strpos(duratadelladisoccupazione, "totale")


* Drop observations for the years outside 2005-2020 (but keep 2004 to detrend)
drop if strpos(time, "Q") | strpos(time, "2021") | strpos(time, "2022")
 
destring time, replace

rename time year 
label var year "Year"

* Keep the observations for all regions combined 
keep if strpos(territorio, "Italia") 

rename territorio region 

* Keep the observations for all the total of the age group
keep if strpos(classedietà, "15-64 anni")

rename classedietà age

* Unemployment rate
rename value unemployment_rate

*** Sort the dataset ***
sort year 

drop if year == 2020

*** Generate a unique identifier variable ***
gen AID = _n


*** Save the cleaned dataset ***
keep AID year unemployment_rate 


save "$projectpath/data/raw/clean/allAgesUnemploymentRateMale.dta", replace 

**********************
*** Draw the graph ***
**********************

*************************
*** Descriptive graph ***
*************************
clear all 

*** Merge the cleaned datasets ***
use "$datapath/clean/allAgesMaleDeathRate.dta"

merge m:1 AID using "$datapath/clean/allAgesUnemploymentRateMale.dta"

tsset year
sort year

drop if year == 2004

* Draw the graph
* Create line plot with years on the x-axis on the y-axis the standard devaition from the mean 
set scheme s1color

* Specify tick positions with more space between major ticks
local tick_positions 2005(5)2020

* Generate the graph
twoway (scatter unemployment_rate year, connect(l) msymbol(d) ytitle("Rate (%)") lc(blue) mcolor(blue)) || ///
       (scatter death_rate year, connect(l) ytitle("Rate (%)") lc(red) mcolor(red)), ///
       xtitle("Year") xla(`tick_positions') ///
       legend(label(1 "Male Unemployment Rate") label(2 "Male Death Rate") pos(6) col(1) region(fc(white)))

*** Export and save the graph ***
graph export "$projectpath/outputs/Graphs/maleDeathsUnempDescriptiveGraph.png", replace


*************************************
*** Detrended and normalize graph ***
*************************************
clear all 

*** Merge the cleaned datasets ***
use "$datapath/clean/allAgesMaleDeathRate.dta"

merge m:1 AID using "$datapath/clean/allAgesUnemploymentRateMale.dta"

tsset year
sort year

* Detrend and normalize male death rate
gen pct_deaths = death_rate - l.death_rate

egen mean_deaths = mean(pct_deaths)
egen sd_deaths = sd(pct_deaths)

gen norm_pct_deaths = (pct_deaths - mean_deaths) / sd_deaths


* Detrend and normalize unemployment rate
gen pct_ur = unemployment_rate - l.unemployment_rate

egen mean_ur = mean(pct_ur)
egen sd_ur = sd(pct_ur)

gen norm_pct_ur = (pct_ur - mean_ur) / sd_ur

* Create line plot with years on the x-axis on the y-axis the standard devaition from the mean 
set scheme s1color

* Specify tick positions with more space between major ticks
local tick_positions 2005(5)2020

* Generate the graph
twoway (scatter norm_pct_ur year, connect(l) msymbol(d) ytitle("Standard Deviation From Mean") lc(blue) mcolor(blue)) || ///
       (scatter norm_pct_deaths year, connect(l) ytitle("Standard Deviation From Mean") lc(red) mcolor(red)), ///
       xtitle("Year") xla(`tick_positions') ///
       legend(label(1 "Male Unemployment Rate") label(2 "Male Death Rate") pos(6) col(1) region(fc(white)))

*** Export and save the graph ***
graph export "$projectpath/outputs/Graphs/maleDeathsUnempGraph.png", replace




**************************************************
*** GRAPH - FEMALE UNEMPLOYMENT AND DEATH RATE ***
**************************************************
clear all 
set more off
cap log close

*******************************************
*** Clean the unemployment rate dataset ***
*******************************************
*** Import the original dataset about the disoccupation rate in csv format ***
import delimited "$datapath/DCCV_TAXDISOCCU1 - Tasso di disoccupazione - intero ds.csv"

*** Clean the dataset ***

* Drop observations for female sex only
keep if strpos(sesso, "femmine")

rename sesso sex

* Drop observations for not needed detailed variables
keep if strpos(titolodistudio, "totale")

keep if strpos(v12, "totale")

keep if strpos(duratadelladisoccupazione, "totale")


* Drop observations for the years outside 2005-2020 (but keep 2004 to detrend)
drop if strpos(time, "Q") | strpos(time, "2021") | strpos(time, "2022")
 
destring time, replace

rename time year 
label var year "Year"

* Keep the observations for all regions combined 
keep if strpos(territorio, "Italia") 

rename territorio region 

* Keep the observations for all the total of the age group
keep if strpos(classedietà, "15-64 anni")

rename classedietà age

* Unemployment rate
rename value unemployment_rate

*** Sort the dataset ***
sort year 

drop if year == 2020

*** Generate a unique identifier variable ***
gen AID = _n


*** Save the cleaned dataset ***
keep AID year unemployment_rate 

save "$projectpath/data/raw/clean/allAgesUnemploymentRateFemale.dta", replace 

 



********************************
*** Clean the deaths dataset ***
********************************
clear all

*** Import the original dataset about deaths in csv format ***
import delimited "$datapath/DCIS_MORTALITA1 - Tavole di mortalità - intero ds.csv"

*** Clean the dataset ***
keep if strpos(tipo_dato15, "DEATHS")

keep if strpos(sesso, "femmine")

drop if strpos(eta1, "-") > 0

* Keep the observations for all regions combined 
keep if strpos(territorio, "Italia") 

* Drop observations for the years outside 2005-2020 (but keep 2004 to detrend)
keep if 2004 <= time & time <=2020

rename time year 
label var year "Year"

* Keep the observations for the age group 15-64 and sum the deaths value for each year
gen numeric_eta1 = real(regexs(1)) if regexm(eta1, "Y(\d+)")

keep if 15 <= numeric_eta1 & numeric_eta1 <= 64

gen age_category = . 
replace age_category = 1 if numeric_eta1 >= 15 & numeric_eta1 <= 64

egen deaths = total(value) if !missing(age_category), by(year)

label var deaths "Total female deaths (15-64 years old)"

*** Keep only a set of observations for each year ***
keep if strpos(etàeclassidietà, "61 anni") 

*** Sort the dataset ***
sort year

*** Generate a unique identifier variable ***
gen AID = _n


*** Save the cleaned dataset ***
keep AID year deaths 

save "$projectpath/data/raw/clean/allAgesFemaleDeaths.dta", replace 


*** Merge the dataset with the population dataset to obtain death rate ***
clear all

* Clean the dataset 
import delimited "$datapath/DCIS_RICPOPRES2011_01022024092337849.csv"

* Keep observations for females only
rename sesso sex
label var sex "Sex"

keep if strpos(sex, "femmine")

* Rename variable time 
rename time year
label var year "Year"

* Rename variable age 
rename eta1 age 
label var age 

* Create a numeric variable for all the region 
rename territorio region
label var region "Region"

keep if strpos(region, "Italia")

egen region_numeric = group(region), label

* Create age classes and sum the deaths value for each year
gen age_numeric = real(regexs(1)) if regexm(age, "Y(\d+)")

gen age_category = . 
replace age_category = 1 if age_numeric >= 15 & age_numeric <=  64

* Keep only one observation for each age class
keep if age_numeric == 15 

* Generate a variable that takes the sum of all deaths count
egen population = total(value) if !missing(age_category), by(year)

*** Sort dataset ***
sort year region_numeric age_category sex

* Generate a unique identifier variable
gen AID = _n

*** Save the cleaned dataset ***
keep AID age_category sex year region region_numeric population

save "$projectpath/data/raw/clean/allAgesPopulationFemale.dta", replace 



* Merge the datasets 
clear all

use "$datapath/clean/allAgesFemaleDeaths.dta"

merge m:1 AID using "$datapath/clean/allAgesPopulationFemale.dta"

*** Calculate death rate per 1,000 females
gen death_rate = (deaths / population) * 1000

drop _merge 

* Save the dataset 
save "$projectpath/data/raw/clean/allAgesFemaleDeathRate.dta", replace 




**********************
*** Draw the graph ***
**********************
*************************
*** Descriptive graph ***
*************************
clear all 

*** Merge the cleaned datasets ***
use "$datapath/clean/allAgesFemaleDeathRate.dta"

merge m:1 AID using "$datapath/clean/allAgesUnemploymentRateFemale.dta"

tsset year
sort year

drop if year == 2004

* Draw the graph
* Create line plot with years on the x-axis on the y-axis the standard devaition from the mean 
set scheme s1color

* Specify tick positions with more space between major ticks
local tick_positions 2005(5)2020

* Generate the graph
twoway (scatter unemployment_rate year, connect(l) msymbol(d) ytitle("Rate (%)") lc(blue) mcolor(blue)) || ///
       (scatter death_rate year, connect(l) ytitle("Rate (%)") lc(red) mcolor(red)), ///
       xtitle("Year") xla(`tick_positions') ///
       legend(label(1 "Female Unemployment Rate") label(2 "Female Death Rate") pos(6) col(1) region(fc(white)))

	   
*** Export and save the graph ***
graph export "$projectpath/outputs/Graphs/femaleDeathsUnempDescriptiveGraph.png", replace
	   
	   

*************************************
*** Detrended and normalize graph ***
*************************************
clear all 


*** Merge the cleaned datasets ***
use "$datapath/clean/allAgesFemaleDeathRate.dta"

merge m:1 AID using "$datapath/clean/allAgesUnemploymentRateFemale.dta"

tsset year
sort year

* Detrend and normalize total deaths
gen pct_deaths = death_rate - l.death_rate

egen mean_deaths = mean(pct_deaths)
egen sd_deaths = sd(pct_deaths)

gen norm_pct_deaths = (pct_deaths - mean_deaths) / sd_deaths


* Detrend and normalize unemployment rate
gen pct_ur = unemployment_rate - l.unemployment_rate

egen mean_ur = mean(pct_ur)
egen sd_ur = sd(pct_ur)

gen norm_pct_ur = (pct_ur - mean_ur) / sd_ur

* Create line plot with years on the x-axis on the y-axis the standard devaition from the mean 
set scheme s1color

* Specify tick positions with more space between major ticks
local tick_positions 2005(5)2020

* Generate the graph
twoway (scatter norm_pct_ur year, connect(l) msymbol(d) ytitle("Standard Deviation From Mean") lc(blue) mcolor(blue)) || ///
       (scatter norm_pct_deaths year, connect(l) ytitle("Standard Deviation From Mean") lc(red) mcolor(red)), ///
       xtitle("Year") xla(`tick_positions') ///
       legend(label(1 "Female Unemployment Rate") label(2 "Female Death Rate") pos(6) col(1) region(fc(white)))

*** Export and save the graph ***
graph export "$projectpath/outputs/Graphs/femaleDeathsUnempGraph.png", replace


