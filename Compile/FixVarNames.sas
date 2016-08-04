/* MACRO %FixVarNames
Version: 	1.01
Author: 	Daniel Mastropietro
Created: 	03-Feb-2016
Modified: 	16-Jun-2016 (previous: 28-May-2016)

DESCRIPTION:
Fix variable names by shortening their number of characters to a specified
maximum minus a specified space.

Name conflicts are resolved by replacing the name of the shortened name with
an appropriate number.

Useful to make sure that all remain SAS valid variable names after adding
a prefix or suffix of fixed length.

USAGE:
%FixVarNames(var, max=32, space=0, replace=, replacement=, log=1);

REQUIRED PARAMETERS:
- var:				List of variables to fix.

OPTIONAL PARAMETERS:
- max:				Maximum number of characters allowed for each variable
					name including the margin space defined by parameter SPACE.
					default: 32 (i.e. the maximum allowed number of chars in SAS)

- space:			Number of characters to leave as margin space for a prefix or
					suffix to be added to the variable name before exceeding
					the number of characters given in MAX.
					default: 0

- replace:			One or more consecutive characters to replace in the original
					variable name prior to fixing their name (only applied when the
					variable actually needs to be shortened).
					default: (empty)

- replacement:		One ore more characters to replace the characteres indicated in
					REPLACE=.
					default: (empty)

- log:				Show messages in the log?
					Possible values: 0 => No, 1 => Yes
					default: 1

RETURNED VALUES:
The list in input parameter 'var' where names have been shortened to the number
of characters given by max - space.
All variable names are trimmed on the right.

NOTES:
1.- No check is done for repeated variable names after truncation.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %FindInList
- %GetNroElements
- %SelectNames

EXAMPLES:
1.- %FixVarNames(thisisalongname v234567890test, max=10, space=2);
Returns the list 'thisisal v2345678'.

2.- %FixVarNames(A_ID_PERIODO A_TEST V_CR_SAMPLE_SUM, max=20, space=10, replace=_);
Returns the list 'AIDPERIODO A_TEST VCRSAMPLES'

APPLICATIONS:
1.- Use this macro to shorten the variable names to make sure that when adding
a prefix or a suffix to them (with e.g. %MakeList) each generated variable name
is a valid SAS variable.
*/
&rsubmit;
%MACRO FixVarNames(var, max=32, space=0, replace=, replacement=, log=1) / store des="Fixes variable names by shortening their names to an allowed maximum minus a space";
%local i j;
%local maxlen;			%* Maximum length allowed for the variable name based on parameters MAX= and SPACE=;
%local lastchar;		%* Position of the last character to keep in each variable name (this is used to avoid an out-of-range error in the %substr() macro when trimming variable names);
%local nro_vars;
%local changed;			%* List of 0s and 1s indicating which variable names were changed by the process;
%local changedi;
%local vari;
%local varfix;
%local varfixi;			%* Fixed variable name after the first step;
%local newname;			%* Proposed new variable name to resolve conflicts;
%local nro_matches;		%* Number of conflicts + 1 (so, if &nro_matches = 1 there is no conflict);
%local resolved;		%* Whether the conflict was resolved;
%local list1;
%local list2;
%local nreplace;
%local number;
%local foundPositions;

%*** 1.- First fixing step, where variable names are shortened but no conflicting names are checked;
%let nro_vars = %GetNroElements(&var);
%let maxlen = %eval(&max - &space);
%let changed = ;
%do i = 1 %to &nro_vars;
	%let vari = %scan(&var, &i, ' ');

	%* Check if there would be any changes in the variable name by comparing the variable name length
	%* with the maximum allowed name length (MAXLEN): if the former is smaller or equal, then the variable name should not be changed;
	%if %length(&vari) <= &maxlen %then %do;
		%* No changes in the variable name;
		%let varfixi = &vari;
		%let changed = &changed 0;
	%end;
	%else %do;
		%* First shorten the variable by replacing the characters specified in REPLACE= if any;
		%if %quote(&replace) ~= %then
			%let vari = %sysfunc(transtrn(&vari, &replace, &replacement));
		%* FIX the variable name;
		%let lastchar = %sysfunc(min(%length(&vari), &maxlen));
		%let varfixi = %substr(&vari, 1, &lastchar);
		%let changed = &changed 1;
	%end;
	
	%* Update the list of output variable names;
	%let varfix = &varfix &varfixi;
%end;


%*** 2.- Check for conflicting names and resolve them;
%do i = 1 %to &nro_vars;
	%let changedi = %scan(&changed, &i, ' ');
	%if &changedi %then %do;
		%*** Only check if there is a conflict when the name has changed, o.w. we always keep the original name;
		%* Read both the original and first version of fixed variable names;
		%let vari = %scan(&var, &i, ' ');
		%let varfixi = %scan(&varfix, &i, ' ');

		%* Look for possible appearances of the variable name in the list;
		%let foundPositions = %FindInList(&varfix, &varfixi, log=0);
		%let nro_matches = %GetNroElements(&foundPositions);
		%if &nro_matches > 1 %then %do;
			%* If there is more than one match resolve conflicts by shortening the variable name and adding a number at the end;
			%let resolved = 0;
			%let number = 1;

			%* Loop until the problem is solved;
			%do %until(&resolved);
				%* Number of characters to replace with the number;
				%let nreplace = %length(&number);
				%let lastchar = %length(&varfixi) - &nreplace;
				%if &lastchar < 1 %then %do;
					%put FIXVARNAMES: WARNING - Cannot resolve conflict without making an invalid variable name starting with a number.;
					%put FIXVARNAMES: The variable name will NOT be changed to resolve the conflict (%upcase(&varfixi)).;
					%put FIXVARNAMES: Try increasing the number of characters allowed in the variable name (MAX=&max);
					%put FIXVARNAMES: or decrease the space to be left after name shortening (SPACE=&space).;
					%let newname = &varfixi;
					%let resolved = 1;
				%end;
				%else %do;
					%let newname = %substr(&varfixi, 1, &lastchar)&number;

					%* Check if the new name no longer exists in the list of variables to fix;
					%* If that is that case, we are done, if not increase the number to use at the end of the name by 1;
					%if %quote(%FindInList(&varfix, &newname, log=0)) = 0 %then %do;
						%let resolved = 1;
						%if &log %then
							%put FIXVARNAMES: Variable name changed to resolve conflict: %upcase(&vari) --> %upcase(&newname);
					%end;
					%else
						%let number = %eval(&number + 1);
				%end;
			%end;

			%* Update the name in the list of fixed variable names;
			%let list1 = ;
			%let list2 = ;
			%if &i > 1 %then
				%let list1 = %SelectNames(&varfix, 1, &i-1);
			%if &i < &nro_vars %then
				%let list2 = %SelectNames(&varfix, &i+1, &nro_vars);
			%let varfix = &list1 &newname &list2;
		%end;
		%else %if &log %then
			%put FIXVARNAMES: Variable name changed: %upcase(&vari) --> %upcase(&varfixi);
	%end;
%end;

&varfix
%MEND FixVarNames;
