/* Categorize-Test.sas
Created: 		15-Feb-2016
Author: 		Daniel Mastropietro
Description: 	Tests run on macro %Categorize
Dependencies:	%RunTestHarness macro
Notes:			The test code makes use of a test harness defined in the same directory.
*/

* Setup;
%let testmacro = Categorize;
%let testpath = E:\SAS\Macros\DMMacros\tests\&testmacro;
libname test "&testpath";

* Read the Test Harness dataset;
%import(TestHarness_&testmacro, "&testpath\TestHarness-&testmacro..csv");

/*======================================== 2016/02/04 =======================================*/
*** Version 1.0: where I have re-written the macro from scracth to make use of PROC RANK;

* Run all tests;
%RunTestHarness(&testmacro, TestHarness_&testmacro, library=test);

* Run selected tests if needed;
options mprint;
%RunTestHarness(&testmacro, TestHarness_&testmacro, library=test, testcases=18 17);
options nomprint;
/*======================================== 2016/02/04 =======================================*/
