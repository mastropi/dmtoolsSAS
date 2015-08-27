/* MACRO %PrintNameList
Version: 1.02
Author: Daniel Mastropietro
Created: 22-Oct-04
Modified: 24-Sep-05

DESCRIPTION:
This macro either prints in a single column (in the output window) or creates a dataset with
column NAME containing the names in a given list. The length of column NAME is the length of
the longest name in the list.
Optionally the dataset is transposed so that there is only one observation with all
the values passed in the list.

USAGE:
%PrintNameList(
	list,			*** List of names.
	out=,			*** Output dataset with the list of names in one column.
	sep=%quote( )	*** Separator used to separate the names in the list.
	type=char,		*** Type of variable to create in the output dataset.
	sort=0, 		*** Should the list of names be sorted alphabetically?
	transpose=0		*** Transpose output dataset to have only one observation with all the names?
	title=,			*** Unquoted title to show when printing the list of names in the output window.
	log=1);			*** Show messages in the log?

REQUIRED PARAMETERS:
- list:			List of names to print or to be stored in the output dataset.

OPTIONAL PARAMETERS:
- sep:			Separator used to separate the names in the list.
				The search for 'sep' in the lists in order to determine the names
				present in the list is CASE SENSITIVE.
				default: %quote( ) (i.e. the blank space)

- out:			Output dataset where the list of names is stored in one column named NAME.
				If no output dataset is specified, the list of names is printed in
				the output window.
				No data options can be specified.

- type:			Type of variable to create in output dataset.
				Possible values are: NUM (for numeric variables), CHAR (for character variables)
				Default: CHAR

- sort:			Should the list of names be sorted alphabetically?
				Possible values: 0 => No, 1 => Yes
				default: 0

- transpose:	Should the output dataset be transposed to have only one observation with all
				the values in the list?
				In case a transpose is requestsed, the column names in the output dataset
				are name1, name2, ..., name<n>, where n is the number of names in 'list'.
				Possible values: 0 => No, 1 => Yes
				default: 0

- title:		Title to show when printing the list of names in the output window.
				The title should be unquoted and is set at a title2 level.
				When the list of names to print is passed using a macro variable, a useful
				title is the name of such macro variable.

- log:			Show messages in the log?
				Possible values: 0 => No, 1 => Yes
				default: 1

NOTES:
1.- If no output dataset is specified, the list of names is printed in the output window.
2.- The macro %MakeListFromVar does the same thing as this macro. In fact, that macro
calls this macro. The reason for its existence is that its name is more descriptive of what
the macro does.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %GetNroElements
- %ResetSASOptions
- %SetSASOptions

EXAMPLES:
1.- %PrintNameList(&list, sort=1, title=list);
Prints the list of names in macro variable &list in the output window in a single column
after sorting them in alphabetically order (since sort=1).
The title 'list' is shown at the top of the list.

2.- %PrintNameList(&list, out=Varlist);
Generates the dataset VARLIST with the list of names in macro variable &list, shown in the
order they appear in &list (since sort=0 by default).

3.- %PrintNameList(&list, out=Varlist, transpose=1);
Generates the dataset VARLIST with the list of names in macro variable &list, shown in the
order they appear in &list (since sort=0 by default).

4.- %PrintNameList(%quote(&list), sep=%quote(,), sort=1, title=Comma separated list);
Prints the comma separated list of names stored in macro variable &list in the output window
in a single column.

APPLICATIONS:
1.- Show a list of names in an easy-to-read way (because the list of names is shown in the
output window in a single column)

2.- Create a dataset with the contents of a macro variable, where each element of the macro
variable is stored in a different row of the dataset.
*/
&rsubmit;
%MACRO PrintNameList(list, sep=%quote( ), out=, type=CHAR, sort=0, transpose=0, title=, log=1)
		/ store des="Shows a list of names in the output window or creates a dataset with the list";
%local i length maxlength nro_names _out_;

%SetSASOptions;

%if &log %then %do;
	%put;
	%put PRINTNAMELIST: Macro starts;
	%put;
%end;

/*--------------------------------- Parsing input parameters --------------------------------*/
%* If SEP= is blank, redefine it as the blank space using function %quote;
%* This is necessary for the %scan function to work properly;
%if %quote(&sep) = %then
	%let sep = %quote( );

%let nro_names = %GetNroElements(%quote(&list), sep=%quote(&sep));

%if %quote(&out) = %then 
	%let _out_ = _CVL_out_;
%else
	%let _out_ = %scan(&out, 1, '(');	%* Any data options are eliminated;
/*-------------------------------------------------------------------------------------------*/

%if &nro_names > 0 %then %do;
	data &_out_;
		%* Compute length of largest string;
		%let maxlength = 0;
		%do i = 1 %to &nro_names;
			%let name = %sysfunc(compbl( %scan(%quote(&list), &i, %quote(&sep)) ));
			%let length = %length(%quote(&name));
			%if &length > &maxlength %then
				%let maxlength = &length;
		%end;

		%if %upcase(&type) = CHAR %then %do;
			length name $&maxlength;
		%end;
		%else %do;
			length name 5;
		%end;
		%do i = 1 %to &nro_names;
			%if %upcase(&type) = CHAR %then %do;
				name = compbl("%scan(%quote(&list), &i, %quote(&sep))");
				if substr(name, 1, 1) = " " then
					name = substr(name, 2);
				%** The above IF is used because the COMPBL function used above does not eliminate
				%** all the blanks at the beginning. It only eliminates multiple blanks,
				%** but it always leaves a single blank if there are blanks present at the
				%** beginning of the string;
			%end;
			%else %do;
				name = %scan(%quote(&list), &i, %quote(&sep));
				%** In this case, a COMPBL function is not necessary because the data is numeric
				%** (as specified by the user in parameter TYPE=);
			%end;
			output;
		%end;
	run;
%end;
%else %do;
	%* Create dataset with no observations;
	data &_out_;
		%if %upcase(&type) = CHAR %then %do;
/*			length name $100;*/
			name = "";
		%end;
		%else %do;
			length 5;
			name = .;
		%end;
		if 0 then output;	%* This generates a dataset with the variables created and no observations;
	run;
	%if &log %then
		%put PRINTNAMELIST: The list is empty.;
%end;

%if &sort %then %do;
	proc sort data=&_out_;
		by name;
	run;
%end;

%if &transpose %then %do;
	proc transpose data=&_out_ out=&_out_(drop=_NAME_) prefix=name;
		var name;
	run;
%end;

%if &log and %quote(&out) ~= %then %do;
	%if &transpose %then %do;
		%put PRINTNAMELIST: Output dataset %upcase(&_out_) created with one observation and &nro_names columns;
		%put PRINTNAMELIST: containing the list of names present in the list passed.;
		%put PRINTNAMELIST: The column names are name1 ... name&nro_names.;
	%end;
	%else %do;
		%put PRINTNAMELIST: Output dataset %upcase(&_out_) created with column NAME containing;
		%put PRINTNAMELIST: the list of &nro_names names present in the list passed.;
	%end;
%end;

%* Print list in output window;
%if &nro_names > 0 and %quote(&out) = %then %do;
	%if %quote(&title) ~= %then %do;
		title2 "&title";
	%end;
	proc print data=&_out_;
	run;
	%if %quote(&title) ~= %then %do;
		title2;
	%end;
	%if &log %then
		%put PRINTNAMELIST: The list of names is shown in the output window.;
%end;
proc datasets nolist;
	delete _CVL_out_;
quit;

%if &log %then %do;
	%put;
	%put PRINTNAMELIST: Macro ends;
	%put;
%end;

%ResetSASOptions;
%MEND PrintNameList;