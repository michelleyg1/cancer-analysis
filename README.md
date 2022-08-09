# diabetes-analysis
I completed this analysis as a personal project to strengthen my data analytics skills in SAS and to explore how cause-specific death rate for a very prevalent health problem in the United states, Diabetes, has changed from 2014 to 2021 within different states.
I used four datasets for this analysis,
	-Weekly Provisional Counts of Death by State and Select Causes, 2020-2022
	-Weekly Counts of Death by State and Select Causes, 2014-2019
	-United States Census Bureau. Annual Population Estimates, Estimated Components of Resident Population Change, and Rates of the Components of Resident Population Change for the United States, States, District of Columbia, and Puerto Rico: April 1, 2020 to July 1, 2021
	-Population, Population Change, and Estimated Components of Population Change: April 1, 2010 to July 1, 2019

	In preparing this data for analysis I faced several challenges, one of them being that I had to merge these tables together to calculate cause-specific death rate for diabetes as this requires a population measurement to perform. 
	The population data was calculated on a yearly level, measured at mid year, while the death count data was in Weeks, therefore I had to create an accumulating column that accumulated in groups of state to get the yearly value of deaths from Diabetes from 2014 to 2021.
	Another issue in the Weekly Counts of death data was that the counts for New York State and New York City were seperated, while the population data from the Census Bureau had only the whole state of New York. I utiilzed the data step and proc SQL to use my knowledge of Structured Query Language to create a summed value of Diabetes deaths for the State of New York, including the city. 
	Lastly, the population data was in a wide format, while the diabetes deaths data was in a narrow format. I used my knowledge of transposing datasets to create a narrow version of the population table for merging with the diabetes deaths table, so that it could be merged by year.
	I was then able to calculate the cause-specific death rate using the following equation:

	Number of Deaths assigned to a specific cause during a given time interval (year) / mid-interval population * 100,000

	I also transposed the final single table to wide format, as I found this easier to read and perform analysis on.

	I then created an interactive data visualization using Tableau to display my findings in a simple to understand format, using the value of the color to show the scale of diabetes rate, and created a slider that can be used to toggle between the years that were included in the dataset (2014-2021).

	Citations

	National Center for Health Statistics. Weekly Provisional Counts of Deaths by State and Select Causes, 2020-2022. Available from https://data.cdc.gov/d/muzy-jte6.

	National Center for Health Statistics. Weekly Counts of Deaths by State and Select Causes, 2014-2019. Date accessed [Last accessed date]. Available from https://data.cdc.gov/d/3yf8-kanr.

	United States Census Bureau. Population, Population Change, and Estimated Components of Population Change: April 1, 2010 to July 1, 2019. Available from https://www.census.gov/data/datasets/time-series/demo/popest/2010s-state-total.html

	United States Census Bureau. Annual Population Estimates, Estimated Components of Resident Population Change, and Rates of the Components of Resident Population Change for the United States, States, District of Columbia, and Puerto Rico: April 1, 2020 to July 1, 2021 (NST-EST2021-ALLDATA). Available from https://www.census.gov/data/datasets/time-series/demo/popest/2020s-state-total.html
