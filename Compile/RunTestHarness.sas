/* MACRO %RunTestHarness
Version:	1.0
Author:		Daniel Mastropietro
Created:	12-Feb-2016
Modified:	12-Feb-2016

DESCRIPTION:
Runs a set of tests on a given macro. The macro parameter values for each test are read
from a SAS dataset containing one column per parameter to set.

REQUIRED PARAMETERS:
- macro:			Macro name to test (w.o. %)
					Ex: Categorize

- data:				Dataset containing all possible test cases to run, with the parameter
					values to use for each test.
					This dataset should have a column called CASE with the test ID and
					one column for each parameter to set out of the parameters received by
					the macro to test.
					IMPORTANT: The name of each column should coincide with the name of
					the macro parameter.
					Optionally the dataset can have the following additional columns:
					_DESCRIPTION:	Describes what the test case tests.
					_EXPECT:		Describes what to expect as a result of the test.
					_RESULT:		Indicates whether the test should be a successful ('S')
									or a failure ('F').

OPTIONAL PARAMETERS:
- testcases:		Blank-separated list of test IDs to run.
					The test IDs are those given in column CASE of input dataset DATA.
					default: all test IDs given in column CASE of input dataset DATA

- testfrom:			First test number to run out of the TESTCASES list.
					default: 1

- testto:			Last test number to run out of the TESTCASES list.
					default: number of cases to test as per parameter TESTCASES
*/
&rsubmit;
%MACRO RunTestHarness(macro, data, testcases=, testfrom=, testto=) / store des="Runs a set of tests on a specified macro";

%local c;					%* Test case index;
%local i;
%local colname;
%local macrovars;			%* MACROVARS contains the macro variable names that stores the list of values for each parameter of the macro, although it includes the test case number which is not a parameter;
%local nro_macrovars;
%local nro_tests;
%local paramname;			%* Parameter name;
%local paramvalue;
%local signature;			%* Macro signature to pass to the macro call;
%local sep;
%local testcaseList;		%* Test case numbers to run;
%local testcase;			%* Test case number to run among the test cases numbers read from the dataset with the test parameters;
%local descriptionFlag;
%local expectFlag;
%local resultFlag;

%SetSASOptions;
%ExecTimeStart(maxlevel=2);

%* Read the columns in the input dataset into macro variable MACROVARS so that we can construct the macro signature from them;
proc contents data=&data out=_rth_pc noprint;
run;
proc sort data=_rth_pc;
	by varnum;
run;
%let macrovars = %MakeListFromVar(_rth_pc, var=name, log=0);
%let macrovars = %MakeList(&macrovars, suffix=List);
%*%let macrovars = caseList dataList varList byList idList conditionList varcatList varvalueList valueList groupsizeList groupsList descendingList outList addvarsList;
%let sep = |;				%* Separator to use between the different values of each parameter (each column);

%if ~%FindInList(%upcase(&macrovars), caseList, log=0) %then %do;
	%put RUNTESTHARNESS: ERROR - The input dataset %upcase(&data) does NOT contain a column called CASE containing the test ID.;
	%put RUNTESTHARNESS: Macro stops.;
%end;
%else %do;
	%* Check if the columns include description, expectations and results;
	%let descriptionFlag = 0;
	%let expectFlag = 0;
	%let resultFlag = 0;
	%if %FindInList(%upcase(&macrovars), _descriptionList, log=0) %then
		%let descriptionFlag = 1;
	%if %FindInList(%upcase(&macrovars), _expectList, log=0) %then
		%let expectFlag = 1;
	%if %FindInList(%upcase(&macrovars), _resultList, log=0) %then
		%let resultFlag = 1;

	%put Starting tests for macro %upcase(&macro);
	%put Reading test cases from dataset %upcase(&data);

	%*** Read the parameter values of each test case into separate macro variables whose name is given by the names in macro variable MACROVARS;
	%let nro_macrovars = %GetNroElements(&macrovars);
	%do i = 1 %to &nro_macrovars;
		%let macrovar = %scan(&macrovars, &i, ' ');
		%let colname = %substr(&macrovar, 1, %index(&macrovar, List)-1);
		%local &macrovar;
		%put %quote(    READING COLUMN &colname...);
		%let &macrovar = %MakeListFromVar(&data, var=&colname, sep=%quote(&sep), log=0);
	%*	%put &&&macrovar;
	%*	%puts(&&&macrovar, sep=%quote(&sep));
	%end;

	/*-------------------------------- Parse input parameters -----------------------------------*/
	%* Blank separated list of cases: testcaseList;
	%let nro_tests = %GetNroElements(%quote(&caseList), sep=%quote(&sep));
	%let testcaseList = %SelectNames(%quote(&caseList), 1, &nro_tests, sep=%quote(&sep), outsep=%quote( ));

	%* Check if the user specified test cases;
	%if %quote(&testcases) ~= %then %do;
		%let testcaseList = &testcases;
		%* Update the number of tests to run;
		%let nro_tests = %GetNroElements(&testcaseList);
	%end;
	%* Check the TESTFROM and TESTTO parameters that indicate the first and last tests to run
	%* over the testcaseList (which can be either those found in column CASE in the input dataset
	%* or those specified by the user in TESTCASES parameter);
	%if %quote(&testto) ~= %then %do;
		%let testcaseList = %SelectNames(&testcaseList, 1, %sysfunc(min(&testto, &nro_tests)));
		%let nro_tests = %GetNroElements(&testcaseList);
	%end;
	%if %quote(&testfrom) ~= %then
		%let testcaseList = %SelectNames(&testcaseList, %sysfunc(max(1, &testfrom)), &nro_tests);
	/*-------------------------------- Parse input parameters -----------------------------------*/

	%*** Go over the selected cases, prepare the maco signature of the test and run the test;
	%let nro_tests = %GetNroElements(&testcaseList);
	%put The following &nro_tests test cases will be run: &testcaseList;
	%do c = 1 %to &nro_tests;
		%* Get the test case number corresponding to test case c in the testcaseList
		%* (e.g. if testcasList = 3|7|2|1 then testcase for c = 2 is 7);
		%let testcase = %scan(&testcaseList, &c, ' ');
		%* Get the test index in the test case list stored in CASELIST (as this indexes the parameter set to use!)
		%* (e.g. if caseList = 1|2|3|5|7|4 and testcaseList = 3|7|2|1 then testcaseIdx for testcase = 7 is 5,
		%* i.e. the position of test ID 7 in caseList);
		%let caseIdx = %FindInList(%quote(&caseList), &testcase, sep=%quote(&sep), log=0);

		%put;
		%put *************************** Test # &c of &nro_tests. Test ID: &testcase ****************************;
		%* Show test description and expectations if existing;
		%if &descriptionFlag %then
			%put Description: %scan(%quote(&_descriptionList), &caseIdx, %quote(&sep));
		%if &expectFlag %then
			%put Expects: %scan(%quote(&_expectList), &caseIdx, %quote(&sep));
		%if &resultFlag %then
			%put Expected result: %scan(%quote(&_resultList), &caseIdx, %quote(&sep));

		%let signature = ;
		%do i = 1 %to &nro_macrovars;
			%* Get the i-th parameter name and store it in MACROVAR;
			%let macrovar = %scan(&macrovars, &i, ' ');
			%let paramname = %substr(&macrovar, 1, %index(&macrovar, List)-1);

			%* Assign the c-th value for the i-th parameter;
			%let paramvalue = %scan(%quote(&&&macrovar), &caseIdx, %quote(&sep));	%* Need to use %quote() to enclose &&&macrovar in order to consider the blank values at the first position as a valid value;
			%* If the value is missing (.) set it to blank (this happens for numeric parameters);
			%if %quote(&paramvalue) = . %then
				%let paramvalue = ;
/*			%else %if &paramname = condition and %quote(&paramvalue) ~= %then*/
/*				%* Enclose the parameter value in %QUOTE when it accepts more complicated values such as an expression;*/
/*				%let paramvalue = %nrstr(%quote)(&paramvalue);*/
			%if %upcase(&paramname) ~= CASE and %substr(&paramname, 1, 1) ~= _ %then %do;
				%if %quote(&signature) = %then
					%let signature = &paramname=&paramvalue;
				%else
					%let signature = &signature, &paramname=&paramvalue;
			%end;
		%end;

		%* Run the test;
		%put &signature;
		%&macro(&signature);
	%end;
%end;

proc datasets nolist;
	delete _rth_pc;
quit;

%ExecTimeStop;
%ResetSASOptions;

%* Cleanup global macro variables that may have been left around due to macro execution errors during the tests;
%DeleteTrackingMacroVars();
%MEND RunTestHarness;

