*************************************
*************************************
*** This do file provides summary statistics 
*** to decide which fatalities to analysis 
*************************************
*************************************
clear all 
set more off
cap log close

global datapath  "/Users/simonecantalupi/Desktop/Thesis/thesis_Cantalupi_0001092400/replicationStata/data/raw"

global projectpath "/Users/simonecantalupi/Desktop/Thesis/thesis_Cantalupi_0001092400/replicationStata"

*** Import the dataset in csv format ***
import delimited "$datapath/deathsItalyCauses.csv"

* Keep observations for both sexes only
rename sesso sex
label var sex "Sex"

keep if strpos(sex, "totale")

* Rename variable time 
rename time year
label var year "Year"

drop if year == 2004

* Rename variable age 
rename età age 
label var age 

* Keep only the age needed (i.e., up to 64)
drop if strpos(age, "65-69 anni") | strpos(age, "70-74 anni")

* Rename variable cause 
rename causainizialedimorteeuropeanshor cause 
label var cause "Cause of death"

* Obtain the total number of deaths for all age classes
egen total_value = total(value), by(cause)

drop if strpos(cause, "totale")
drop total_value

* Generate a new variable
egen number = total(value), by(cause) 

* Tabulate the variable "cause" with the frequencies based on "value"
tab cause, sum(number) 

egen unique_number = group(number)

* Drop duplicates, keeping only the first occurrence of each value
duplicates drop unique_number, force

*** Generate frequencies ***
gen freq = number / 1096316 * 100

* Generate dataset
keep cause freq number

* Sort data set by the smallest to the largest value
sort freq

* List the 86 causes of death in percentages and absolute values
list cause freq number


