/* PiecewisTransfCuts-Test.sas
Created: 		07-Aug-2017
Modified:		07-Aug-2017
Author: 		Daniel Mastropietro
Description: 	Tests run on macro %PiecewiseTransfCuts
Dependencies:	%RunTestHarness macro
Notes:			The test code makes use of a test harness defined in the same directory.
*/


/*---------------------------- Run Test Harness ---------------------------------*/
*** Version 1.0 (04-Feb-2016): where I have re-written the macro from scracth to make use of PROC RANK;
* Setup;
%let testmacro = PiecewiseTransfCuts;
%let testpath = E:\Daniel\SAS\Macros\tests\&testmacro;
libname test "&testpath";

* Read the Test Harness dataset;
%import(TestHarness_&testmacro, "&testpath\TestHarness-&testmacro..csv");

* Run all tests;
%RunTestHarness(
	&testmacro,
	TestHarness_&testmacro,
	library=test,
	checkoutput=out outall,
	resultsdir=&testpath/expected
);
/*---------------------------- Run Test Harness ---------------------------------*/



/*------------------------ Generate expected results ----------------------------*/
* Setup;
%let testmacro = PiecewiseTransfCuts;
%let testpath = E:\Daniel\SAS\Macros\tests\&testmacro;
libname test "&testpath";

* Read the Test Harness dataset;
%import(TestHarness_&testmacro, "&testpath\TestHarness-&testmacro..csv");

%RunTestHarness(
	&testmacro,
	TestHarness_&testmacro,
	library=test,
	checkoutput=out outall,
	saveoutput=1,
	resultsdir=&testpath/expected
);
/*------------------------ Generate expected results ----------------------------*/
