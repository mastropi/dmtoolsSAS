/* MACRO %RunTestHarness
Version:	1.05
Author:		Daniel Mastropietro
Created:	12-Feb-2016
Modified:	18-Jul-2018 (previous: 09-Jan-2018, 21-Jun-2017, 20-Mar-2016, 17-Mar-2016)

DESCRIPTION:
Runs a set of tests on a given macro. The macro parameter values for each test are read
from a Test Harness SAS dataset containing one column per parameter to set.

If the tested macro returns a value, this returned value or result can be compared with
the expected returned value read from the Test Harness dataset (see below).

If the tested macro generates output datasets, they can be compared with expected outputs
stored in the RESULTSDIR directory (see below).

Note that a macro can EITHER return a value OR generate output datasets. It cannot do both
(unless the macro uses the FCMP feature in SAS).

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
					_RESULT:		Indicates whether the test should be a success ('S')
									or a failure ('F').

OPTIONAL PARAMETERS:
- testcases:		Blank-separated list of test IDs to run.
					The test IDs are those given in column CASE of input dataset DATA.
					default: all test IDs given in column CASE of input dataset DATA

- testfrom:			First test number to run out of the TESTCASES list.
					default: 1

- testto:			Last test number to run out of the TESTCASES list.
					default: number of cases to test as per parameter TESTCASES

- checkresult:		Whether the result or returned value of the macro should be compared against
					the expected returned value for the test given in column _EXPECT of the
					Test Harness dataset.
					This only works when the macro returns a value, o.w. set it to 0.
					Possible values: 0 => No, 1 => Yes
					default: 0

- checkoutput:		Blank-separated list of output datasets to compare with expected outputs.
					These names should correspond to the PARAMETER names of the macro under test
					that take output dataset names as their values. Ex: OUT, OUTSTAT, etc.
					The comparison is carried out using PROC COMPARE where the BASE dataset is
					the expected output and the COMPARE dataset is the observed output.
					The output of PROC COMPARE is saved to a dataset whose content is only printed
					when it contains observations as only the differing observations are saved to
					that dataset.
					default: (empty)

- comparecriterion:	Value of the CRITERION= option in the PROC COMPARE statement when comparing
					the expected with the observed datasets.
					This criterion is used for comparing numeric variables by concluding that the
					two compared values are the same if their absolute difference is larger than
					the specified criterion value.
					default: 1E-10

- saveoutput:		Whether to save the output datasets generated by the macro and listed in
					the CHECKOUTPUT parameter.
					Set this to 1 if running the test harness for the first time and the
					generated outputs should be saved for future regression tests.
					The output datasets are saved only when CHECKRESULT=0.
					Possible values: 0 => No, 1 => Yes
					default: 0

- library:			Library name to add to the name of the dataset to be used for each test
					as read from the DATA column in the test harness dataset passed in parameter DATA.
					If the dataset name is fully qualified with a library name in the test
					harness dataset then this parameter is ignored.
					This library is defined as a temporary library mapped to the DATADIR= directory
					when this parameter is given.
					default: WORK

- datadir:			Unquoted directory name where the input datasets whose name is read from
					the test harness dataset which are used to run the macro are located.
					If the dataset name is fully qualified with a library name in the test
					harness dataset then this parameter is ignored.
					default: (empty)

- resultsdir:		Unquoted directory name where the results datasets are located.
					These datasets are the datasets against which the output datasets generated
					by the macro and listed in CHECKOUTPUT= should be compared.
					These names should be the same as the name of the output datasets generated
					by the macro.
					default: (empty)

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %CallMacro
- %DeleteTrackingMacroVars
- %ExectTimeStart
- %ExecTimeStop
- %FindInList
- %FindMatch
- %GetNObs
- %GetNroElements
- %MakeList
- %MakeListFromVar
- %Rep
- %ResetSASOptions
- %SelectNames
- %SetSASOptions

EXAMPLES:
1.- Generate the expected results based on the TestHarness_&testmacro dataset:
%let testmacro = EvaluationChart;
%let testpath = E:\Daniel\SAS\Macros\tests\&testmacro;
%RunTestHarness(
	&testmacro,
	TestHarness_&testmacro,
	library=_data,
	checkoutput=OUT OUTSTAT,
	saveoutput=1,
	resultsdir=&testpath\expected
);

2,- Run the Test Harness unit tests defined in the TestHarness_&testmacro dataset:
%let testmacro = EvaluationChart;
%let testpath = E:\Daniel\SAS\Macros\tests\&testmacro;
%RunTestHarness(
	&testmacro,
	TestHarness_&testmacro,
	checkoutput=OUT OUTSTAT,
	datadir=&testpath\data,
	resultsdir=&testpath\expected
);

*/
&rsubmit;
%MACRO RunTestHarness(
		macro,
		data,
		testcases=,
		testfrom=,
		testto=,
		checkresult=0,
		checkoutput=,
		comparecriterion=1E-10,
		saveoutput=0,
		library=WORK,
		datadir=,
		resultsdir=) / store des="Runs a set of tests on a specified macro";

%local c;					%* Test case index;
%local i;
%local colname;
%local expect;				%* Expected result (used when checkresult=1);
%local expectedResult;		%* Expected result in terms of Success or Failure;
%local fail;				%* Counter for number of failed tests;
%local macrovars;			%* MACROVARS contains the macro variable names that stores the list of values for each parameter of the macro, although it includes the test case number which is not a parameter;
%local ndiff;				%* Number of differing observations between the observed and expected datasets when CHECKOUT=1;
%local at_least_one_output_different;	%* Whether at least for one of the output datasets the observed and expected outputs are different;
%local nro_macrovars;
%local nro_tests;
%local nspaces;				%* Spaces to leave between the markers of pass or fail test when showing the tests summary;
%local outdata;				%* Stores the output dataset to check with a pre-specified result stored in the RESULTSDIR= directory;
%local outnamevalue;		%* Name-value pair defining the output parameter and its value to check;
%local nro_output;			%* Nro. of output datasets to check;
%local paramname;			%* Parameter name;
%local paramvalue;
%local pass;				%* Counter for number of passed tests;
%local result;				%* Result of the macro run (i.e. value returned by the macro if any);
%local signature;			%* Macro signature to pass to the macro call;
%local sep;
%local status;				%* List containing the status of each test run (. => OK, X => wrong result, F => test expected to fail);
%local testcaseList;		%* Test case numbers to run;
%local testcase;			%* Test case number to run among the test cases numbers read from the dataset with the test parameters;
%local descriptionFlag;		%* Indicates whether a Desription column is present in dataset DATA;
%local expectFlag;			%* Indicates whether an Expect column is present in dataset DATA;
%local resultFlag;			%* Indicates whether a Result column is present in dataset DATA;

%SetSASOptions;
%ExecTimeStart(maxlevel=2);

%* Show input parameters;
%put;
%put RUNTESTHARNESS: Macro starts;
%put;
%put RUNTESTHARNESS: Input parameters:;
%put RUNTESTHARNESS: - Macro under test = %quote(&macro);
%put RUNTESTHARNESS: - Input dataset = %quote(   &data);
%put RUNTESTHARNESS: - testcases = %quote(       &testcases);
%put RUNTESTHARNESS: - testfrom = %quote(        &testfrom);
%put RUNTESTHARNESS: - testto = %quote(          &testto);
%put RUNTESTHARNESS: - checkresult = %quote(     &checkresult);
%put RUNTESTHARNESS: - checkoutput = %quote(     &checkoutput);
%put RUNTESTHARNESS: - comparecriterion = %quote(&comparecriterion);
%put RUNTESTHARNESS: - saveoutput = %quote(      &saveoutput);
%put RUNTESTHARNESS: - library= %quote(          &library);
%put RUNTESTHARNESS: - datadir = %quote(         &datadir);
%put RUNTESTHARNESS: - resultsdir = %quote(      &resultsdir);
%put;

%* Map the datadir and resultsdir libraries;
%if %quote(&datadir) ~= %then %do;
	libname _data "&datadir";
	%let library = _data;
%end;
%if %quote(&resultsdir) ~= %then %do;
	libname _results "&resultsdir";
%end;

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

	%*** Go over the selected cases, prepare the macro signature of the test and run the test;
	%let nro_tests = %GetNroElements(&testcaseList);
	%put The following &nro_tests test cases will be run: &testcaseList;
	%* Initialize variables;
	%let pass = 0;
	%let fail = 0;
	%let status = ;
	%do c = 1 %to &nro_tests;
		%* Get the test case number corresponding to test case c in the testcaseList
		%* (e.g. if testcasList = 3 7 2 1 then testcase for c = 2 is 7);
		%let testcase = %scan(&testcaseList, &c, ' ');
		%* Get the test index in the test case list stored in CASELIST (as this indexes the parameter set to use!)
		%* (e.g. if caseList = 1 2 3 5 7 4 and testcaseList = 3 7 2 1 then testcaseIdx for testcase = 7 is 5,
		%* i.e. the position of test ID 7 in caseList);
		%let caseIdx = %FindInList(%quote(&caseList), &testcase, sep=%quote(&sep), log=0);

		%put;
		%put *************************** Test # &c of &nro_tests. Test ID: &testcase ****************************;
		title "Test ID: &testcase";
		%* Show test description and expectations if existing;
		%if &descriptionFlag %then
			%put Description: %scan(%quote(&_descriptionList), &caseIdx, %quote(&sep));
		%if &expectFlag %then %do;
			%let expect =  %scan(%quote(&_expectList), &caseIdx, %quote(&sep));
			%put Expects: &expect;
		%end;
		%if &resultFlag %then %do;
			%* Success or Failure test?;
			%let expectedResult = %scan(%quote(&_resultList), &caseIdx, %quote(&sep));
			%put Expected result: &expectedResult;
		%end;

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
			%else %if %index(%quote(&paramvalue), %quote(,)) %then
				%* Enclose the parameter value in %QUOTE when the parameter value contains a comma to separate e.g. values
				%* (e.g. this may happen in parameter ValuesLetAlone in %PlotBinned macro);
				%let paramvalue = %quote(&paramvalue);

			%* Add the library name passed in parameter LIBRARY to the dataset name used for testing when paramname=DATA;
			%if %upcase(&paramname) = DATA and %quote(&paramvalue) ~= and %quote(&library) ~= %then %do;
				%if %scan(&paramvalue, 2, '.') = %then
					%let paramvalue = &library..&paramvalue;
			%end;

			%* Create the param=value string to pass to the signature of the macro whenever paramname is different from CASE;
			%if %upcase(&paramname) ~= CASE and %substr(&paramname, 1, 1) ~= _ %then %do;
				%if %quote(&signature) = %then
					%let signature = &paramname=&paramvalue;
				%else
					%let signature = &signature, &paramname=&paramvalue;
			%end;
		%end;

		%* Run the test;
		%put &signature;
		%* Spaces to leave between the indicator of the previous test result and the current test result (for the test summary shown at the end);
		%let nspaces = %Rep(%quote( ), %length(&testcase));
		%if ~&checkresult %then %do;
			%* => Do not need to check the returned value by the macro, either because we do not want to check it or the macro does not return any value;
			%* HOWEVER, still we may want to compare output datasets (when CHECKOUTPUT= lists the output datasets to check), and this is done here;
			%********** THE MACRO IS RUN *******;
			%&macro(&signature);

			%* Check the output datasets listed in parameter CHECKOUTPUT= if the macro is not expected to fail;
			%if %upcase(&expectedResult) = F %then %do;
				%let status = &status&nspaces.F;
				%put Macro is expected to FAIL... no comparisons of output datasets are performed.;
			%end;
			%else %do;
				%let nro_output = %GetNroElements(&checkoutput);
				%let at_least_one_output_different = 0;
				%do i = 1 %to &nro_output;
					%let outdata = %scan(&checkoutput, &i, ' ');
					%* Look for the &OUTDATA keyword in the macro signature;
					%* First remove the commas from the SIGNATURE because o.w. the %INDEX function used inside %FindMatch
					%* gives error!;
					%let signature = %sysfunc(transtrn(%quote(&signature), %quote(,), ));
					%let outnamevalue = %FindMatch(%quote(&signature), key=&outdata=, log=0);
					%if %quote(&outnamevalue) ~= %then %do;
						%let outdata = %scan(&outnamevalue, 2, '=');
						%if %quote(&outdata) ~= %then %do;
							%if &saveoutput %then %do;
								%put Saving output dataset %upcase(&outnamevalue) as expected dataset in RESULTSDIR...;
								data _results.&outdata;
									set &outdata;
								run;
							%end;
							%else %do;
								%put Comparing output dataset %upcase(&outnamevalue) with expected dataset stored in RESULTSDIR...;
								proc compare base=_results.&outdata compare=&outdata out=_rth_compare_ outnoequal noprint method=absolute criterion=&comparecriterion;
									%** OUTNOEQUAL makes the output dataset contain only differing cases;
								run;
								%callmacro(getnobs, _rth_compare_ return=1, ndiff);
								%if &ndiff = 0 %then %do;
									%put OK - datasets are equal.;
								%end;
								%else %do;
									%let at_least_one_output_different = 1;
									title1 "RUNTESTHARNESS: Observed and Expected datasets %upcase(&outdata) DIFFER!";
									title2 "First 10 records that compare differently";
									proc print data=_rth_compare_(obs=10);
									run;
									title2;
									title1;
								%end;
							%end;
						%end;
					%end;
				%end;

				%* Update the indicator of failed tests;
				%if &at_least_one_output_different = 0 %then %do;
					%let status = &status&nspaces..;
					%let pass = %eval(&pass + 1);
				%end;
				%else %do;
					%let status = &status&nspaces.X;
					%let fail = %eval(&fail + 1);
				%end;
			%end;
		%end;
		%else %do;
			%* => Check the returned value by the macro by comparing it with the expected returned value read from the Test Harness dataset (above);
			%****** THE MACRO IS RUN *******;
			%let result = %&macro(&signature);
			%if %upcase(&expectedResult) = F %then
				%let status = &status&nspaces.F;
			%else %do;
				%* Compare the returned value (RESULT) with the expected returned value (EXPECT);
				%if &result = &expect %then %do;
					%let status = &status&nspaces..;
					%let pass = %eval(&pass + 1);
					%put RUNTESTHARNESS: Test result OK;
				%end;
				%else %do;
					%let status = &status&nspaces.X;
					%let fail = %eval(&fail + 1);
					%put RUNTESTHARNESS: WARNING - Result not as expected;
					%put RUNTESTHARNESS: Result: &result;
				%end;
			%end;
		%end;
	%end;
%end;

%* SUM UP;
%if &checkresult or %quote(&checkoutput) ~= %then %do;
	%put;
	%put *********************************************************;
	%put SUMMARY OF TESTS EXECUTION:;
	%put Test IDs run: &testcaseList;
	%put Test status: &status;
	%put (. => OK, X => wrong result, F => test expected to fail);
	%put # run: &nro_tests;
	%put # non-failed tests: %eval(&pass + &fail);
	%put # passed: &pass;
	%put # failed: &fail;
	%put *********************************************************;
%end;

%* Remove the title;
title;

%* Remove the library mappings;
%if %quote(&datadir) ~= %then %do;
libname _data;
%end;
%if %quote(&resultsdir) ~= %then %do;
libname _results;
%end;

proc datasets nolist;
	delete 	_rth_pc
			_rth_compare_;
quit;

%ExecTimeStop;
%ResetSASOptions;

%* Cleanup global macro variables that may have been left around due to macro execution errors during the tests;
%DeleteTrackingMacroVars();
%MEND RunTestHarness;
