*****************************
*****************************
*** BUSINESS CYCLE  GRAPH ***
*****************************
clear all 
set more off
cap log close

global datapath  "/Users/simonecantalupi/Desktop/Thesis/thesis_Cantalupi_0001092400/replicationStata/data/raw"

global projectpath "/Users/simonecantalupi/Desktop/Thesis/thesis_Cantalupi_0001092400/replicationStata"


*** Import the original dataset about the disoccupation rates in csv format ***
import excel "$datapath/dec1433f-7fb4-41da-8cb9-72ed887fd1d9.xlsx", firstrow

br

*** Clean the dataset ***

* Select only the variables needed 
keep if strpos(Country, "Italy")

drop Country 

drop Year 

* Rename variables based on label information 
foreach v of var F-BS {
    local lbl : var label `v'

    // Remove non-alphanumeric characters from the label
    local lbl : subinstr local lbl "[^A-Za-z0-9]" "", all
    
    // Convert label to a valid variable name
    local lbl = strtoname("`lbl'")
	
	// Check if the label starts with an underscore and remove it
    local lbl : subinstr local lbl "^_" "", all
    
    // Rename variable
    rename `v' year`lbl'
}

* Select the time period needed (i.e., 2005-2020)
drop year_2025-year_2020

drop year_2003-year_1960


* Reshape, destring and rename variables
reshape long year_, i(Unit) string j(year)

rename year_ gdp

destring gdp, replace

destring year, replace 

tsset year

sort year

*** Calculate GDP growth rate as a percentage ***
// Generate a new variable 'gdp_growth' representing the GDP growth rate
// Formula: ((Current GDP / Lagged GDP) - 1) * 100
gen gdp_growth = (gdp / L.gdp - 1) * 100

*** Generate the graph ***
twoway scatter gdp_growth year || ///
      scatter gdp_growth year, connect(l) legend(off) ytitle("GDP growth rate (%)") ///
      yline(0, lpattern(dash))


*** Export and save the graph ***
graph export "$projectpath/outputs/Graphs/scatterGDP.png", replace	  
	  
	  

