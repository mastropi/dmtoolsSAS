/* Aggregate-Test.sas
Created: 		20-Jul-2018
Modified:		20-Jul-2018
Author: 		Daniel Mastropietro
Description: 	Tests run on macro %Aggregate
Dependencies:	%RunTestHarness macro
Notes:			The test code makes use of a test harness defined in the same directory.
				Test data generation code:
					data totest;
						infile datalines delimiter="," dsd missover;
						length id $10;
						input id $ fecha turno $ x y grp;
						length y 3;
						informat fecha date9.;
						format fecha date9.;
						datalines;
					A,01jan2017,N,3.2,1,5
					A,02jan2017,N,3.5,1,.
					A,03jan2017,M,8,0,4
					B,20May2017,M,.,0,.
					B,21May2017,N,9,0,4
					B,27may2017,T,3.1,0,3
					B,27may2017,N,0.0,1,4
					C,27may2017,T,1.2,1,3
					C,04Jun2017,T,4.5,0,3
					C,05Jun2017,T,8.1,0,2
					;

					* Then copy the dataset just created;o
					libname data "E:\Daniel\SAS\Macros\tests\Aggregate\data";
					proc copy in=work out=data;
						select totest;
					run;
*/


/*---------------------------- Run Test Harness ---------------------------------*/
* Setup;
%let testmacro = Aggregate;
%let testpath = E:\Daniel\SAS\Macros\tests\&testmacro;
libname test "&testpath";

* Read the Test Harness dataset;
%import(TestHarness_&testmacro, "&testpath\TestHarness-&testmacro..csv");

* Run all tests;
%RunTestHarness(
	&testmacro,
	TestHarness_&testmacro,
	library=test,
	checkoutput=out,
	resultsdir=&testpath/expected
);
/*---------------------------- Run Test Harness ---------------------------------*/



/*------------------------ Generate expected results ----------------------------*/
* Setup;
%let testmacro = Aggregate;
%let testpath = E:\Daniel\SAS\Macros\tests\&testmacro;
libname test "&testpath";

* Read the Test Harness dataset;
%import(TestHarness_&testmacro, "&testpath\TestHarness-&testmacro..csv");

%RunTestHarness(
	&testmacro,
	TestHarness_&testmacro,
	library=test,
	checkoutput=out,
	saveoutput=1,
	resultsdir=&testpath/expected
);
/*------------------------ Generate expected results ----------------------------*/
