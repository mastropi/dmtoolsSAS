/* InformationValue-Test.sas
Created: 		17-Aug-2005
Modified: 		17-Jun-2017 (previous: 12-Aug-2006)
Author: 		Daniel Mastropietro
Description: 	Tests run on macro %InformationValue.
*/


/*----------------------------- Run Test Harness --------------------------------*/
* Setup;
%let testmacro = InformationValue;
%let testpath = E:\Daniel\SAS\Macros\tests\&testmacro;
libname test "&testpath";
options fmtsearch=(WORK _data);

* Read the Test Harness dataset;
%import(TestHarness_&testmacro, "&testpath\TestHarness-&testmacro..csv");

%RunTestHarness(
	&testmacro,
	TestHarness_&testmacro,
	checkoutput=OUT OUTWOE OUTFORMAT,
	datadir=&testpath\data,
	resultsdir=&testpath\expected
);
/*----------------------------- Run Test Harness --------------------------------*/



/*------------------------ Generate expected results ----------------------------*/
* Create ad-hoc datasets for testing;
%let testmacro = InformationValue;
%let testpath = E:\Daniel\SAS\Macros\tests\&testmacro;
libname _data "&testpath\data";		%* This test data library name should coincide with the name used by the %RunTestHarness macro when mapping the DATADIR directory;
options fmtsearch=(WORK _data);

*** Test case 0: Extreme data;
*** One variable has all its values equal, another has all missing values;
*** Target variable with a few missing values;
data _data.totest_00_extreme;
	input x_allequal x_allmissing x_ok y;
	datalines;
1 . 2 0
1 . 2 .
1 . 3 1
1 . 3 0
1 . 3 1
1 . . .
1 . . 1
1 . . 0
;

*** Test case 1: Test dataset taken from "Credit Scoring for Risk Managers" de Elizabeth Mays, pag. 97.
*** The values of WOE and IV are shown as a reference of what the values should be;
data _data.totest_01_maysbook;
	input group good bad WOE IV;
	length z $5;
	do i = 1 to good;
		obs = _N_;
		y = 0; 
		z = "Good";
		output;
	end;
	do i = 1 to bad;
		obs = _N_;
		y = 1; 
		z = "Bad";
		output;
	end;
	length z $5;
	drop good bad;
	datalines;
1	12125	31	1.35	0.050
2	12112	44	1.00	0.032
3	12126	30	1.38	0.052
4	12118	38	1.15	0.039
5	12107	49	0.89	0.026
6	12091	65	0.61	0.014
7	12098	59	0.71	0.018
8	12084	72	0.51	0.010
9	12101	55	0.78	0.021
10	12044	112	0.06	0.000
11	12087	69	0.55	0.012
12	12085	71	0.52	0.011
13	12062	94	0.24	0.003
14	12105	52	0.83	0.024
15	12126	30	1.38	0.052
16	12125	31	1.35	0.050
17	11975	181	-0.43	0.011
18	11959	197	-0.51	0.017
19	11524	632	-1.71	0.374
20	11691	466	-1.40	0.206
;
* The IV total value is 1.022;

proc freq data=_data.totest_01_maysbook;
	tables group*y;
run;

* Format for group to test parameter FORMAT=;
proc format library=_data;
	value group 1-8 = '1-8'
				9-13 = '9-13'
				14-20 = '14-20';
run;

* Read the Test Harness dataset;
%import(TestHarness_&testmacro, "&testpath\TestHarness-&testmacro..csv");

* Run tests and save the EXPECTED results;
options nomprint;
%RunTestHarness(
	&testmacro,
	TestHarness_&testmacro,
	library=_data,
	checkoutput=OUT OUTWOE OUTFORMAT,
	saveoutput=1,
	resultsdir=&testpath\expected
);
/*------------------------ Generate expected results ----------------------------*/
