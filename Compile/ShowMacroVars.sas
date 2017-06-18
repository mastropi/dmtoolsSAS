/* MACRO %ShowMacroVars
Version:		1.00
Author:			Daniel Mastropietro
Created:		28-May-2016
Modified:		28-May-2016

DESCRIPTION:
Shows a set of macro variables and their values in the output and in the log windows and
creates an output dataset containing them.

The output dataset name is called MACROVARS_<yyyymmddTHHmmss> where
the suffix is the time stamp when the macro is run.

USAGE:
%ShowMacroVars(macrovars, maxlength=50);

REQUIRED PARAMETERES:
- macrovars:	Blank-separated list of macro variable names to show.

OPTIONAL PARAMETERS:
- maxlength:	Maximum length of the value of the macro variables to show.
				default: 50

- sort:			Whether to sort the macro variables alphabetically.
				Possible values: 0 => No, 1 => Yes
				default: 1

- store:		Whether to store the macro variable names and values in a
				dataset called MacroVars_<yyyymmddTHHmmss>.
				default: 1

- library:		Library where the output dataset is stored.
				default: WORK

APPLICATIONS:
This macro can be used to show a set of parameters defined to run a process
in the output window, so that they are clearly seen by the user.
*/
&rsubmit;
%MACRO ShowMacroVars(macrovars, maxlength=50, sort=1, store=1, library=WORK) / store des="Shows the values of a set of macro variables in the output and in the log";
%local i;
%local nro_macrovars;
%local macroName;
%local macroValue;

%if &sort %then %do;
	title "MACRO VARIABLE VALUES (sorted alphabetically)";
	%put *************************************************************************;
	%put MACRO VARIABLE VALUES:;
%end;
%else %do;
	title "MACRO VARIABLE VALUES";
	%put *************************************************************************;
	%put MACRO VARIABLE VALUES:;
%end;

%let nro_macrovars = %GetNroElements(&macrovars);
%let datetime = %TRIM(%SYSFUNC(DATETIME(), B8601DT.));	* Formato yyyymmddThhmmss;
data &library..MacroVars_&datetime;
	length macrovar $20 value $&maxlength nchar order 3;
	%do i = 1 %to &nro_macrovars;
		%let macroName = %scan(&macrovars, &i, ' ');
		%let macroValue = &&&macroName;
		%put &macroName = %quote(%rep(%quote( ), 35 - %length(&macroName))) &macroValue;
		macrovar = "&macroName";
		%* Largo de los nombres de los datasets;
		%if %index(&macroValue, .) > 0 %then %do;
		nchar = length(scan("&macroValue", 2, '.'));
		%end;
		%else %do;
		nchar = length("&macroValue");
		%end;
		value = "&macroValue";
		order = &i;
		output;
	%end;
%put *************************************************************************;

%if &sort %then %do;
	proc sort; by macrovar;
%end;
proc print; run;
title;

%if ~&store %then %do;
	proc datasets library=&library nolist;
		delete MacroVars_&datetime;
	quit;
%end;
%MEND ShowMacroVars;