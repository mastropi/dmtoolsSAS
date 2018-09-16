/* Psi-Test.sas
Created: 		16-Sep-2018
Modified:		16-Sep-2018
Author: 		Daniel Mastropietro
Description: 	Tests run on macro %Psi
Dependencies:	%RunTestHarness macro
Notes:			The test code makes use of a test harness defined in the same directory.
*/


/*---------------------------- Run Test Harness ---------------------------------*/
* Setup;
%let testmacro = Psi;
%let testpath = E:\Daniel\SAS\Macros\tests\&testmacro;
libname test "&testpath";

* Read the Test Harness dataset;
%import(TestHarness_&testmacro, "&testpath\TestHarness-&testmacro..csv");

* Run all tests;
%RunTestHarness(
	&testmacro,
	TestHarness_&testmacro,
	library=test,
	checkoutput=out outpsi,
	resultsdir=&testpath/expected
);
/*---------------------------- Run Test Harness ---------------------------------*/



/*------------------------ Generate expected results ----------------------------*/
* Setup;
%let testmacro = Psi;
%let testpath = E:\Daniel\SAS\Macros\tests\&testmacro;
libname test "&testpath";
libname expected "&testpath/expected";

* Read the Test Harness dataset;
%import(TestHarness_&testmacro, "&testpath\TestHarness-&testmacro..csv");

%RunTestHarness(
	&testmacro,
	TestHarness_&testmacro,
	library=test,
	checkoutput=out outpsi,
	saveoutput=1,
	resultsdir=&testpath/expected
);
/*------------------------ Generate expected results ----------------------------*/
