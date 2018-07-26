/* MACRO %CreateVarList
Version: 1.00
Author: Daniel Mastropietro
Created: 20-Oct-04
Modified: 22-Oct-04

DESCRIPTION:
This macro creates a dataset with a column containing the variable names passed in a
list and present in an input dataset.

USAGE:
%CreateVarList(
	data,		*** Input dataset where the variables in the list are searched for
	list,		*** List of variables of interest
	out=,		*** Output dataset with the list of variables of interest in one column
	sort=, 		*** Should the list of variables be sorted alphabetically?
	log=1);		*** Show messages in the log?

REQUIRED PARAMETERS:
- data:			Name of the dataset to which the variables listed in 'list' belong.
				Data options can be specified as in a data= SAS option, but they are
				ignored.

- list:			Blank-separated list of variables whose list is requested.

OPTIONAL PARAMETERS:
- out:			Output dataset where the list of variables is stored in one column
				named VAR.
				If no output dataset is specified, the list of variables is printed in
				the output window.
				Data options can be passed but they are ignored.

- sort:			Should the list of variables be sorted alphabetically?
				Possible values: 0 => No, 1 => Yes
				default: 1

- log:			Show messages in the log?
				Possible values: 0 => No, 1 => Yes
				default: 1

NOTES:
If no output dataset is specified, the list of variables is printed in the output window.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %Callmacro
- %Getnobs
- %ExistVar
- %ResetSASOptions
- %SetSASOptions

SEE ALSO:
- %CreateVarFromList
- %PrintNameList
- %MakeListFromVar

EXAMPLES:
1.- %CreateVarList(test, &list);
This prints the list of variables present in dataset TEST that are listed in macro variable
&list in the output window on a single column.

2.- %CreateVarList(test, &list, out=Varlist, sort=0);
This generates the dataset VARLIST with the list of variables present in dataset TEST
that are listed in macro variable &list, listed in the order they appear in &list
(since sort=0).

APPLICATIONS:
This macro can be used to show a list of variables present in a macro variable in a single
column.
*/

/* PENDIENTE:
- (22/10/04): Modificar la macro de manera que liste las variables que encuentra en el
input dataset.
*/
%MACRO CreateVarList(data, list, out=, sort=1, log=1)
		/ des="Searches for a list of variables in a dataset and Shows the variables that are present";
%local data_name label_option nobs _out_;

%SetSASOptions;

%if &log %then %do;
	%put;
	%put CREATEVARLIST: Macro starts;
	%put;
%end;

%if ~%ExistVar(&data, &list, log=0, macrovar=notfound) %then %do;
	%put CREATEVARLIST: ERROR - Not all variables in the list are present in dataset %upcase(&data).;
	%put CREATEVARLIST: The following variables were not found:;
	%put &notfound;
	%* Deleting global macro variable created in %ExistVar;
	%symdel notfound;
	quit;
%end;
%else %do;
	%if %quote(&out) = %then 
		%let _out_ = _CVL_out_;
	%else
		%let _out_ = %scan(&out, 1, '(');	%* Any data options are eliminated;

	%let label_option = %sysfunc(getoption(label));

	%let data_name = %scan(&data, 1, '(');
	%* Remove the use of labels because I do not want the variable _NAME_ in the
	%* transposed dataset to have a label, because otherwise I would need to spend time
	%* removing it;
	options nolabel;
	data _CVL_temp_;
		set &data_name(obs=1 keep=&list);
	run;
	proc transpose data=_CVL_temp_ out=&_out_(keep=_NAME_ rename=(_NAME_=var));
		var &list;
	run;
	%if &sort %then %do;
		proc sort data=&_out_;
			by var;
		run;
	%end;

	%if &log and %quote(&out) ~= %then %do;
		%Callmacro(getnobs, &_out_ return=1, nobs);
		%put CREATEVARLIST: Output dataset %upcase(&_out_) created with &nobs observations and;
		%put CREATEVARLIST: column VAR containing the list of variables present in the list passed.;
	%end;

	%* Print list in output window;
	%if %quote(&out) = %then %do;
		proc print data=&_out_;
		run;
		%if &log %then
			%put CREATEVARLIST: The list of variables passed is shown in the output window.;
	%end;
	proc datasets nolist;
		delete 	_CVL_temp_
				_CVL_out_;
	quit;

	%* Restore label option;
	options &label_option;
%end;

%if &log %then %do;
	%put;
	%put CREATEVARLIST: Macro ends;
	%put;
%end;

%ResetSASOptions;
%MEND CreateVarList;
