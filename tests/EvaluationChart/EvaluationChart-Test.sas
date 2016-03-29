/* EvaluationChart-Test.sas
Created: 		19-Mar-2016
Author: 		Daniel Mastropietro
Description: 	Tests run on macro %EvaluationChart
Dependencies:	%RunTestHarness macro
Notes:			The test code makes use of a test harness dataset defined in the same directory.
*/

/*-------------------- Create datasets used for testing -------------------------*/
libname test "E:\SAS\Macros\DMMacros\tests\EvaluationChart\data";

* All non-events;
data test.totest_00a;
	input y p leaf;
datalines;
0 0.01 1
0 0.23 2
0 0.01 1
;
* All events;
data test.totest_00b;
	input y p leaf;
datalines;
1 0.01 1
1 0.23 2
1 0.01 1
;

data test.totest_01;
	input y p leaf;
datalines;
0 0.01 1
0 0.23 2
0 0.01 1
1 0.01 1
0 0.15 3
0 0.15 3
1 0.23 2
0 0.26 4
1 0.28 5
1 0.65 6
;

* Perfect ordering with just one event;
data test.totest_02;
	input y p leaf;
datalines;
0 0.01 1
0 0.23 2
0 0.01 1
0 0.01 1
0 0.15 3
0 0.15 3
0 0.23 2
0 0.26 4
0 0.28 5
1 0.65 6
;
/*-------------------- Create datasets used for testing -------------------------*/


/*---------------------------- Run Test Harness ---------------------------------*/
* Setup;
%let testmacro = EvaluationChart;
%let testpath = E:\SAS\Macros\DMMacros\tests\&testmacro;
libname test "&testpath";

* Read the Test Harness dataset;
%import(TestHarness_&testmacro, "&testpath\TestHarness-&testmacro..csv");

%RunTestHarness(
	&testmacro,
	TestHarness_&testmacro,
	checkoutput=OUT OUTSTAT,
	datadir=&testpath\data,
	resultsdir=&testpath\results
);
/*---------------------------- Run Test Harness ---------------------------------*/
