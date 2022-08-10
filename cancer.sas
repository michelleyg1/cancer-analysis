/* Creating Library and Importing Files */
%let path=/home/u61896790/cancer;
libname cancer "/home/u61896790/cancer";

options validvarname=v7;
proc import datafile="&path/input_data/Weekly_Provisional_Counts_of_Deaths_by_State_and_Select_Causes__2020-2022.csv" 
	dbms=csv out=cancer.deaths2020_2022 replace;
	guessingrows=max;
	getnames=yes;
run;

options validvarname=v7;
proc import datafile="&path/input_data/Weekly_Counts_of_Deaths_by_State_and_Select_Causes__2014-2019.csv" 
	dbms=csv out=cancer.deaths2014_2019 replace;
	guessingrows=max;
	getnames=yes;
run;

/* Total Deaths from Diabetes Table*/
proc sort data=cancer.deaths2020_2022;
	by Jurisdiction_of_Occurrence MMWR_Year MMWR_Week;
run;

proc sort data=cancer.deaths2014_2019;
	by Jurisdiction_of_Occurrence MMWR_Year MMWR_Week;
run;

data cancer.deaths2014_2022;
	merge cancer.deaths2020_2022 cancer.deaths2014_2019;
	by Jurisdiction_of_Occurrence MMWR_Year MMWR_Week;
	keep Jurisdiction_of_Occurrence MMWR_Year Total_Cancer_Deaths Malignant_neoplasms__C00_C97_;
	where MMWR_Year ~=2022;
	if first.MMWR_Year=1 then
	Total_Cancer_Deaths=0;
	Total_Cancer_Deaths + Malignant_neoplasms__C00_C97_;
	if last.MMWR_Year=1;
run;

/* Checking every state has correct year values */
proc freq data=cancer.deaths2014_2022;
	tables MMWR_Year;
run;

/* Checking for outliers */
proc means data=cancer.deaths2014_2022;
	var Total_Cancer_Deaths;
run;

proc univariate data=cancer.deaths2014_2022;
	var Total_Cancer_Deaths;
run;

/* Combine New York and NYC */
data nyc;
	set cancer.deaths2014_2022;
	where Jurisdiction_of_Occurrence="New York" or 
		Jurisdiction_of_Occurrence="New York City";
	if Jurisdiction_of_Occurrence="New York City" then
		Jurisdiction_of_Occurrence="New York Merged";
	if Jurisdiction_of_Occurrence="New York" then
		Jurisdiction_of_Occurrence="New York Merged";
run;

proc sql;
	create table nyc_merged AS
	(select Jurisdiction_of_Occurrence, 
			MMWR_Year, 
			sum(Total_Cancer_Deaths) AS Total_Cancer_Deaths 
	from nyc 
	group by Jurisdiction_of_Occurrence, MMWR_Year);
quit;

/* Merge NYC combined table with original table, drop Original NY Values */
proc sort data=nyc_merged;
	by Jurisdiction_of_Occurrence MMWR_Year;
run;

data cancer_merged;
	merge cancer.deaths2014_2022 work.nyc_merged;
	by Jurisdiction_of_Occurrence MMWR_Year;
	where Jurisdiction_of_Occurrence ~= "United States";
	drop Malignant_neoplasms__C00_C97_;
run;

data cancer_clean;
	set work.cancer_merged;
	where Jurisdiction_of_Occurrence not in('New York' 'New York City');
	if Jurisdiction_of_Occurrence="New York Merged" then
		Jurisdiction_of_Occurrence="New York";
run;

proc freq data=work.cancer_clean;
	tables Jurisdiction_of_Occurrence;
run;

/* Find Mid Year Population for each State in 2014-2021 */
/* Importing Files with Mid Year Population */
options validvarname=V7;
proc import datafile="&path/input_data/nst-est2019-alldata.csv" dbms=csv 
	out=pop_2014_2019 replace;
	guessingrows=max;
	getnames=yes;
run;

options validvarname=V7;
proc import datafile="&path/input_data/NST-EST2021-alldata.csv" dbms=csv 
	out=pop_2020_2021 replace;
	guessingrows=max;
	getnames=yes;
run;

/* Merging 2014-2019 table with 2020-2021 table */
proc sort data=work.pop_2014_2019;
	by NAME;
run;

proc sort data=work.pop_2020_2021;
	by NAME;
run;

data pop_merged;
	merge work.pop_2014_2019 work.pop_2020_2021;
	by NAME;
run;

data cancer.midyearpop;
	set pop_merged;
	keep NAME POPESTIMATE2014 POPESTIMATE2015 POPESTIMATE2016 POPESTIMATE2017 
		POPESTIMATE2018 POPESTIMATE2019 POPESTIMATE2020 POPESTIMATE2021;
	where NAME not in ('Midwest Region' 
					'Northeast Region' 
					'South Region' 
					'West Region'
					'United States');
run;

proc transpose data=cancer.midyearpop out=work.midyearpop_narrow;
	var POPESTIMATE2014 POPESTIMATE2015 POPESTIMATE2016 POPESTIMATE2017 POPESTIMATE2018 POPESTIMATE2019 POPESTIMATE2020 POPESTIMATE2021;
	by NAME;
run;

data work.midyearpop_narrowsubstr(rename=(COL1=Population Name=Jurisdiction_of_Occurrence));
	set work.midyearpop_narrow;
	MMWR_Yearchar=strip(tranwrd(_NAME_,"POPESTIMATE", " "));
	MMWR_Year=input(MMWR_Yearchar, 4.);
	drop MMWR_Yearchar _NAME_;
run;
/* Merge with Diabetes Clean Table */
proc sort data=work.midyearpop_narrowsubstr;
	by Jurisdiction_of_Occurrence MMWR_Year;
run;

proc sort data=work.cancer_clean;
	by Jurisdiction_of_Occurrence MMWR_Year;
run;

data work.popcancer_merged;
	merge work.midyearpop_narrowsubstr work.cancer_clean;
	by Jurisdiction_of_Occurrence MMWR_Year;
run;

/* Calculate cause specific death rate for each year */
data cancer.death_rate (rename=(Jurisdiction_of_Occurrence=State MMWR_Year=Year));
	set work.popcancer_merged;
	Cancer_Death_Rate_Per_100000=round((((Total_Cancer_Deaths/Population)*100000)), 0.01);
	drop Population Total_Cancer_Deaths;
run;

/* Transpose to Wide Data for Analysis */
proc transpose data=cancer.death_rate out=cancer.cancer_wide;
	var Cancer_Death_Rate_Per_100000;
	by State;
	id Year;
run;

/* Export to Excel */
data cancer.cancer;
	set cancer.cancer_wide;
	drop _NAME_;
run;

proc export data=cancer.cancer outfile="&path/cancer.xlsx"
	dbms=xlsx replace;
run;
	