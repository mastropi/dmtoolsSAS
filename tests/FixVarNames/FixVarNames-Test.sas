/* FixVarNames-Test.sas
Created: 		17-Mar-2016
Author: 		Daniel Mastropietro
Description: 	Tests run on macro %FixVarNames
Dependencies:	%RunTestHarness macro
Notes:			The test code makes use of a test harness defined in the same directory.
*/

* Setup;
%let testmacro = FixVarNames;
%let testpath = E:\SAS\Macros\DMMacros\tests\&testmacro;
libname test "&testpath";

* Read the Test Harness dataset;
%import(TestHarness_&testmacro, "&testpath\TestHarness-&testmacro..csv");

* Run all tests;
%RunTestHarness(&testmacro, TestHarness_&testmacro, library=test, checkresult=1);
