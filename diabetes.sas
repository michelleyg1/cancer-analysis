/* Creating Library and Importing Files */

libname death "/home/u61896790/death";

options validvarname=v7;
proc import datafile="/home/u61896790/health_conditions/Weekly_Provisional_Counts_of_Deaths_by_State_and_Select_Causes__2020-2022.csv"
dbms=csv out=death.deaths2020_2022 replace;
guessingrows=max;
getnames=yes;
run;

options validvarname=v7;
proc import datafile="/home/u61896790/health_conditions/Weekly_Counts_of_Deaths_by_State_and_Select_Causes__2014-2019.csv"
dbms=csv out=death.deaths2014_2019 replace;
guessingrows=max;
getnames=yes;
run;

/* Exploring Data */

proc contents data=death.deaths2020_2022 varnum;
run;

proc contents data=death.deaths2014_2019 varnum;
run;

proc freq data=death.deaths2020_2022;
tables Jurisdiction_of_Occurrence;
run;

proc freq data=death.deaths2014_2019;
tables Jurisdiction_of_Occurrence;
run;

proc means data=death.deaths2020_2022;
var  Diabetes_mellitus__E10_E14_;
run;

proc means data=death.deaths2014_2019;
var  Diabetes_mellitus__E10_E14_;
run;

/* Total Deaths from Diabetes Table*/

proc sort data=death.deaths2020_2022;
by Jurisdiction_of_Occurrence MMWR_Year MMWR_Week;
run;

proc sort data=death.deaths2014_2019;
by  Jurisdiction_of_Occurrence MMWR_Year MMWR_Week;
run;

data death.diabetes2014_2022;
merge death.deaths2020_2022 death.deaths2014_2019;
by Jurisdiction_of_Occurrence MMWR_Year MMWR_Week;
keep Jurisdiction_of_Occurrence MMWR_Year Total_Diabetes_Deaths;
where MMWR_Year ~= 2022;
if first.MMWR_Year=1 then Total_Diabetes_Deaths=0;
Total_Diabetes_Deaths+ Diabetes_mellitus__E10_E14_;
if last.MMWR_Year=1;
run;

/* Checking every state has correct year values */
proc freq data=death.diabetes2014_2022;
tables MMWR_Year;
run;

/* Checking for outliers */
proc means data=death.diabetes2014_2022;
var Total_Diabetes_Deaths;
run;

proc univariate data=death.diabetes2014_2022;
var Total_Diabetes_Deaths;
run;

/* Combine New York and NYC */
data nyc;
set death.diabetes2014_2022;
where Jurisdiction_of_Occurrence="New York" or 
Jurisdiction_of_Occurrence="New York City";
if Jurisdiction_of_Occurrence="New York City"
then Jurisdiction_of_Occurrence="New York Merged";
if Jurisdiction_of_Occurrence="New York"
then Jurisdiction_of_Occurrence="New York Merged";
run; 


proc sql;
	create table nyc_merged AS(
	select Jurisdiction_of_Occurrence, 
	MMWR_Year,
	sum(Total_Diabetes_Deaths) AS Total_Diabetes_Deaths
	from nyc
	group by Jurisdiction_of_Occurrence, 
	MMWR_Year);
quit;
	
/* Merge NYC combined table with original table, drop Original NY Values */
proc sort data=nyc_merged;
	by Jurisdiction_of_Occurrence 
		MMWR_Year;
run;

data death.diabetes_merged;
	merge death.diabetes2014_2022 work.nyc_merged;
	by Jurisdiction_of_Occurrence MMWR_Year;
run;

data death.diabetes_clean;
	set death.diabetes_merged;
	where Jurisdiction_of_Occurrence not in('New York' 'New York City');
	if Jurisdiction_of_Occurrence = "New York Merged" then Jurisdiction_of_Occurrence="New York";
run;

proc freq data=death.diabetes_clean;
tables Jurisdiction_of_Occurrence;
run;

/* Find Mid Year Population for each State in 2014-2021 */
/* Importing Files with Mid Year Population */
options validvarname=V7;
proc import datafile="/home/u61896790/death/nst-est2019-alldata.csv"
dbms=csv out=midyear_pop_2014_2019 replace;
guessingrows=max;
getnames=yes;
run;

options validvarname=V7;
proc import datafile="/home/u61896790/death/NST-EST2021-alldata.csv"
dbms=csv out=midyear_pop_2020_2021 replace;
guessingrows=max;
getnames=yes;
run;

/* Merging 2014-2019 table with 2020-2021 table */
proc sort data=work.midyear_pop_2014_2019;
by NAME;
run;

proc sort data=work.midyear_pop_2020_2021;
by NAME;
run;

data pop_merged;
	merge work.midyear_pop_2014_2019 work.midyear_pop_2020_2021;
	by NAME;
run;

data death.midyearpop;
	set pop_merged;
	keep NAME POPESTIMATE2014 POPESTIMATE2015 POPESTIMATE2016 POPESTIMATE2017 POPESTIMATE2018 POPESTIMATE2019 POPESTIMATE2020 POPESTIMATE2021;
	where NAME not in ('Midwest Region'
					'Northeast Region'
					'South Region'
					'West Region'
					'United States');
run;

/* proc transpose wide to narrow to stack years, rename years to mmwr year and to fit yyyy format */
/* merge with cleaned diabetes table */
/* calculate cause specific mortality rate for each year */


