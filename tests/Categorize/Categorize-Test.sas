/* Categorize-Test.sas
Created: 		15-Feb-2016
Modified:		19-Jun-2017
Author: 		Daniel Mastropietro
Description: 	Tests run on macro %Categorize
Dependencies:	%RunTestHarness macro
Notes:			The test code makes use of a test harness defined in the same directory.
*/


/*------------------------ Generate expected results ----------------------------*/
* Setup;
%let testmacro = Categorize;
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



/*---------------------------- Run Test Harness ---------------------------------*/
*** Version 1.0 (04-Feb-2016): where I have re-written the macro from scracth to make use of PROC RANK;
* Setup;
%let testmacro = Categorize;
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
