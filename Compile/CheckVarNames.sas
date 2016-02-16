/* MACRO %CheckVarNames
Version: 	1.00
Author: 	Daniel Mastropietro
Created: 	03-Feb-2016
Modified: 	03-Feb-2016

DESCRIPTION:
Check variable names length compared to a maximum allowed number of characters given
by a max value minus a margin space.

Useful to find out which variable names should be changed in order to still comply with
valid SAS variable names after adding a prefix or suffix of fixed length.

USAGE:
%CheckVarNames(var, max=32, space=0);

REQUIRED PARAMETERS:
- var:				List of variables to check.

OPTIONAL PARAMETERS:
- max:				Maximum number of characters allowed for each variable
					name including the space defined by parameter SPACE.
					default: 32 (i.e. the maximum allowed number of chars in SAS)

- space:			Number of characters that would be added to the original variable
					name as a prefix or suffix.
					default: 0

RETURNED VALUES:
The variables in list 'var' whose name exceeds the maximum allowed number of characters
given by max - space.

NOTES:
This macro is intended to be used solely for end user information, i.e. not to be called
from another macro. It is possible, but the macro always prints something in the log.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %GetNroElements

EXAMPLES:
1.- %let var2fix = %CheckVarNames(thisisalongname x v234567890test shortvar, max=10, space=2);
Shows the list:
thisisalongname (7)
v234567890test (6)
and returns the names of the two variables to fix. 

APPLICATIONS:
1.- Use this macro to check which variable names should be shorten and by how much in order 
to make sure their names are still valid after adding a prefix or a suffix (using e.g. %MakeList)
of a fixed length.
*/
&rsubmit;
%MACRO CheckVarNames(var, max=32, space=0) / store des="Checks length of variable names and lists those that exceed an allowed maximum minus a space";
%local i;
%local excess;
%local excessi;
%local maxchar;
%local nro_vars;
%local nro_varout;
%local vari;
%local varout;

%let nro_vars = %GetNroElements(&var);
%let maxchar = %eval(&max - &space);
%let varout = ;
%do i = 1 %to &nro_vars;
	%let vari = %scan(&var, &i, ' ');
	%let excessi = %eval(%length(&vari) - &maxchar);
	%if &excessi > 0 %then %do;
		%let varout = &varout &vari;
		%let excess = &excess &excessi;
	%end;
%end;

%* Give information to the user;
%let nro_varout = %GetNroElements(&varout);
%if &nro_varout > 0 %then %do;
	%* Show the variable names that are too large and for how much they exceed;
	%put CHECKVARNAMES: The following variables do not satisfy the maximum allowed of &maxchar characters;
	%put CHECKVARNAMES: by the number indicated in parenthesis:;
	%do i = 1 %to &nro_varout;
		%put %scan(&varout, &i, ' ') (%scan(&excess, &i, ' '));
	%end;
	%put;
	%put CHECKVARNAMES: Suggested new names are:;
	%do i = 1 %to &nro_varout;
		%put %substr(%scan(&varout, &i, ' '), 1, &maxchar);
	%end;
%end;
%else %do;
	%put CHECKVARNAMES: All variables OK.;
	%put CHECKVARNAMES: They have less than the maximum allowed number of characters (&maxchar).;
%end;

&varout;
%MEND CheckVarNames;
