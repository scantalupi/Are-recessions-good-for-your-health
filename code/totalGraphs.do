************************************
*** DESCRIPTIVE ANALYSIS - GRAPH ***
*************************************
*************************************
*** This do file provides the code to generate a graph that plots for both sexes
*** activity rates against two causes of death
*************************************
*************************************
*************************************
clear all 
set more off
cap log close

global datapath  "/Users/simonecantalupi/Desktop/Thesis/thesis_Cantalupi_0001092400/replicationStata/data/raw"

global projectpath "/Users/simonecantalupi/Desktop/Thesis/thesis_Cantalupi_0001092400/replicationStata"

****************************
*** GENERATE THE DATASET ***
****************************

*********************
*** Activty Rates ***
*********************
clear all

*** Import the original dataset about the activity in csv format ***
import delimited "$datapath/activityRateGraph.csv"

*** Clean the dataset ***
drop if strpos(time, "Q") > 0
keep if strpos(sesso, "totale")

rename value activity_rate

* Sort the dataset 
sort time 

* Generate a unique identifier variable
gen AID = _n

*** Save the cleaned dataset ***
keep AID time activity_rate

br
	 	 
save "$projectpath/data/raw/clean/totalActivityRateGraph.dta", replace 


*********************************
*** Rates for causes of death ***
*********************************
clear all 

*** Import the original dataset about the mortality in csv format ***
import delimited "$datapath/deathGraphs.csv"

* Rename variable time 
rename time year
label var year "Year"

* Rename variable cause 
rename causainizialedimorteeuropeanshor cause 
label var cause "Cause of death"

* Rename variable age 
rename età age 
label var age 

* Generate a variable that takes the sum of all deaths count
*egen deaths = total(value) if !missing(age), by(year)

* Keep only one observation for each age class
*keep if strpos(age, "15-19 anni") 

		
* Generate varibales for cause-specific deaths	
egen transportation_accidents = total(value) if cause == "di cui accidenti di trasporto", ///
	 by(year) 	

egen h_c_amenable = total(value) if cause == "tumori" | cause == "malattie ischemiche del cuore" | cause == "alcune malattie infettive e parassitarie", ///
	 by(year)		
		

* Collapse the dataset 
collapse (sum) transportation_accidents h_c_amenable, by(year)

*** Sort dataset ***
sort year 

* Generate a unique identifier variable
gen AID = _n

*** Save the cleaned dataset ***
keep AID year transportation_accidents h_c_amenable

br
	 	 
save "$projectpath/data/raw/clean/totalDeathsSpecificGraph.dta", replace 		
		
		
*************
*** Rates ***
*************

**********************
*** Mortality rate ***
**********************
clear all 

*** Import the original dataset about the mortality in csv format ***
import delimited "$datapath/mortality.csv"

* Keep observations for both sexes only
rename sesso sex
label var sex "Sex"

keep if strpos(sex, "totale")

* Rename variable time 
rename time year
label var year "Year"

* Rename variable age 
rename età age 
label var age 

* Generate a variable that takes the sum of all deaths count
egen deaths = total(value) if !missing(age), by(year)

* Collapse the dataset 
collapse (sum) deaths, by(year)

* Keep only one observation for each age class
*keep if strpos(age, "15-19 anni") 

*** Sort dataset ***
sort year  

* Generate a unique identifier variable
gen AID = _n

*** Save the cleaned dataset ***
keep AID deaths  year

br

save "$projectpath/data/raw/clean/totalDeathsGraphs.dta", replace 



*** Merge the dataset with the death dataset to obtain rate ***
clear all

use "$projectpath/data/raw/clean/totalDeathsGraphs.dta"

merge m:1 AID using "$datapath/clean/totalDeathsSpecificGraph.dta"

*** Calculate death rate per 1,000 individuals 
gen transportation_accidents_rate = (transportation_accidents / deaths) * 1000 

gen h_c_amenable_rate = (h_c_amenable / deaths) * 1000

drop _merge 

* Save the dataset 
save "$projectpath/data/raw/clean/allAgesTotalDeathRate.dta", replace 




**************************************************
*** Draw the graph for transporation accidents ***
**************************************************
clear all

use "$datapath/clean/allAgesTotalDeathRate.dta"

merge m:1 AID using "$datapath/clean/totalActivityRateGraph.dta"

tsset year
sort year


* Draw the graph
* Create line plot with years on the x-axis on the y-axis the standard devaition from the mean 
set scheme s1color

* Specify tick positions with more space between major ticks
local tick_positions 2005(5)2020

* Generate the graph
twoway (scatter activity_rate year, connect(l) msymbol(d) ytitle("Rate (%)") lc(blue) mcolor(blue)) || ///
       (scatter transportation_accidents_rate year, connect(l) ytitle("Rate (%)") lc(red) mcolor(red)), ///
       xtitle("Year") xla(`tick_positions') ///
       legend(label(1 "Total Activty Rate") label(2 "Transportation Accidents") pos(6) col(1) region(fc(white)))


*** Export and save the graph ***
graph export "$projectpath/outputs/Graphs/transporationAccidentsActivityRateDescriptiveGraph.png", replace
	   
	   
*************************************
*** Detrended and normalize graph ***
**************************************************
clear all

use "$datapath/clean/allAgesTotalDeathRate.dta"

merge m:1 AID using "$datapath/clean/totalActivityRateGraph.dta"

tsset year
sort year

* Detrend and normalize death rate
gen pct_transportation = transportation_accidents_rate - l.transportation_accidents_rate

egen mean_transporation = mean(pct_transportation)
egen sd_transporation = sd(pct_transportation)

gen norm_pct_transporation = (pct_transportation - mean_transporation) / sd_transporation


* Detrend and normalize unemployment rate
gen pct_ar = activity_rate - l.activity_rate

egen mean_ar = mean(pct_ar)
egen sd_ar = sd(pct_ar)

gen norm_pct_ar = (pct_ar - mean_ar) / sd_ar

* Create line plot with years on the x-axis on the y-axis the standard devaition from the mean 
set scheme s1color

* Specify tick positions with more space between major ticks
local tick_positions 2005(5)2020

* Generate the graph
twoway (scatter norm_pct_ar year, connect(l) msymbol(d) ytitle("Standard Deviation From Mean") lc(blue) mcolor(blue)) || ///
       (scatter norm_pct_transporation year, connect(l) ytitle("Standard Deviation From Mean") lc(red) mcolor(red)), ///
       xtitle("Year") xla(`tick_positions') ///
       legend(label(1 "Total Activity Rate") label(2 "Total Transportation Accidents Death Rate") pos(6) col(1) region(fc(white))) ///
       yline(0, lcolor(black) lpattern(dash))

*** Export and save the graph ***
graph export "$projectpath/outputs/Graphs/transporationActivityRateGraph.png", replace






****************************************************
*** Draw the graph for healthcare amenble deaths ***
****************************************************
clear all

use "$datapath/clean/allAgesTotalDeathRate.dta"

merge m:1 AID using "$datapath/clean/totalActivityRateGraph.dta"

tsset year
sort year


* Draw the graph
* Create line plot with years on the x-axis on the y-axis the standard devaition from the mean 
set scheme s1color

* Specify tick positions with more space between major ticks
local tick_positions 2005(5)2020

* Generate the graph
twoway (scatter activity_rate year, connect(l) msymbol(d) ytitle("Rate (%)") lc(blue) mcolor(blue)) || ///
       (scatter h_c_amenable_rate year, connect(l) ytitle("Rate (%)") lc(red) mcolor(red)), ///
       xtitle("Year") xla(`tick_positions') ///
       legend(label(1 "Total Activty Rate") label(2 "Health Care Amenable deaths") pos(6) col(1) region(fc(white)))


*** Export and save the graph ***
graph export "$projectpath/outputs/Graphs/hcAmenableActivityRateDescriptiveGraph.png", replace
	   
	   
*************************************
*** Detrended and normalize graph ***
*************************************
clear all

use "$datapath/clean/allAgesTotalDeathRate.dta"

merge m:1 AID using "$datapath/clean/totalActivityRateGraph.dta"

tsset year
sort year

* Detrend and normalize death rate
gen pct_hc = h_c_amenable_rate - l.h_c_amenable_rate

egen mean_hc = mean(pct_hc)
egen sd_hc = sd(pct_hc)

gen norm_pct_hc = (pct_hc - mean_hc) / sd_hc


* Detrend and normalize unemployment rate
gen pct_ar = activity_rate - l.activity_rate

egen mean_ar = mean(pct_ar)
egen sd_ar = sd(pct_ar)

gen norm_pct_ar = (pct_ar - mean_ar) / sd_ar

* Create line plot with years on the x-axis on the y-axis the standard devaition from the mean 
set scheme s1color

* Specify tick positions with more space between major ticks
local tick_positions 2005(5)2020

* Generate the graph
twoway (scatter norm_pct_ar year, connect(l) msymbol(d) ytitle("Standard Deviation From Mean") lc(blue) mcolor(blue)) || ///
       (scatter norm_pct_hc year, connect(l) ytitle("Standard Deviation From Mean") lc(red) mcolor(red)), ///
       xtitle("Year") xla(`tick_positions') ///
       legend(label(1 "Total Activty Rate") label(2 "Total Health Care Amenable Death Rate") pos(6) col(1) region(fc(white))) ///
       yline(0, lcolor(black) lpattern(dash))

*** Export and save the graph ***
graph export "$projectpath/outputs/Graphs/hcAmenableActivityRateGraph.png", replace

