/* MACRO %VarOrder
Version: 1.00
Author: Daniel Mastropietro
Created: 05-Sep-05
Modified: 05-Sep-05

DESCRIPTION:
Orders the variables in a dataset alphabetically.
Optionally lowcases or upcases their names prior to ordering.
The label of the input dataset is preserved.

USAGE:
%VarOrder(data, case=, out=, log=1);

REQUIRED PARAMETERS:
- data:			Input dataset.

OPTIONAL PARAMETERS:
- case:			Defines whether the variables should be lowcased (=LOWCASE), upcased (=UPCASE)
				or not changed (=<empty>) before setting them in alphabetical order.
				Possible values: LOWCASE, UPCASE
				default: <empty>

- out:			Output dataset where the alphabetical order is set.
				If empty, the alphabetical order is set in the input dataset. 

- log:			Shows messages in the log?
				Possible values: 0 => No, 1 => Yes
				default: 1

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %CreateVarFromList
- %GetVarNames
- %ResetSASOptions
- %SetSASOptions

EXAMPLES:
1.- %VarOrder(test);
Orders variables alphabetically in dataset TEST.

2.- %VarOrder(test, case=upcase);
Upcases and orders variables alphabetically in dataset TEST.

3.- %VarOrder(test, case=lowcase, out=test_ordered);
Creates dataset TEST_ORDERED with variables in dataset TEST lowcased and ordered alphabetically.
*/
&rsubmit;
%MACRO VarOrder(data, case=, out=, log=1)
	/ store des="Orders variables alphabetically in a dataset";
%local data label varnames;
%local createstr1 createstr2 casestr;	%* Strings used in the message to the log;

%SetSASOptions;

%if &log %then %do;
	%put;
	%put VARORDER: Macro starts;
	%put;
%end;

%* Parse input parameters;
%let data = %scan(&data, 1, '(');
%if %quote(&out) = %then
	%let out = &data;
%else
	%let out = %scan(&out, 1, '(');

%* Read variables from dataset;
%let varnames = %GetVarNames(&data);
%* Change case of variables and order alphabetically;
%if %upcase(&case) = UPCASE %then %do;
	%let casestr = upcased and;
	%CreateVarFromList(%upcase(&varnames), out=_VarOrder_varnames_, sort=1, log=0);
%end;
%else %if %upcase(&case) = LOWCASE %then %do;
	%let casestr = lowcased and;
	%CreateVarFromList(%sysfunc(lowcase(&varnames)), out=_VarOrder_varnames_, sort=1, log=0);
%end;
%else %do;
	%let casestr = ;
	%CreateVarFromList(&varnames, out=_VarOrder_varnames_, sort=1, log=0);
%end;
%let varnames = %MakeListFromVar(_VarOrder_varnames_, log=0);
%* Read dataset label;
proc contents data=&data out=_VarOrder_pc_ noprint;
run;
data _NULL_;
	set _VarOrder_pc_(obs=1);
	call symput ('label', memlabel);
run;
%* Order variables alphabetically keeping the dataset label;
data &out(label="&label");
	format &varnames;
	set &data;
run;
%if ~&syserr and &log %then %do;
	%if %quote(%upcase(&out)) ~= %quote(%upcase(&data)) %then %do;
		%let createstr1 = created;
		%let createstr2 = in %upcase(&data);
	%end;
	%else %do;
		%let createstr1 = updated;
		%let createstr2 = ;
	%end;
	%put VARORDER: Dataset %upcase(&out) &createstr1 with variables &createstr2 &casestr ordered alphabetically.;
%end;
%* Delete temporary datasets;
proc datasets nolist;
	delete 	_VarOrder_pc_
			_VarOrder_varnames_;
quit;

%if &log %then %do;
	%put;
	%put VARORDER: Macro ends;
	%put;
%end;

%ResetSASOptions;
%MEND VarOrder;
