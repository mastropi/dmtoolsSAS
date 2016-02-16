/* MACRO %FixVarNames
Version: 	1.00
Author: 	Daniel Mastropietro
Created: 	03-Feb-2016
Modified: 	03-Feb-2016

DESCRIPTION:
Fix variable names by shortening their number of characters to a specified
maximum minus a specified space.

Useful to make sure that all remain SAS valid variable names after adding
a prefix or suffix of fixed length.

USAGE:
%FixVarNames(var, max=32, space=0);

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

RETURNED VALUES:
The list in input parameter 'var' where names have been shortened to the number
of characters given by max - space.
All variable names are trimmed on the right.

NOTES:
1.- No check is done for repeated variable names after truncation.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %GetNroElements

EXAMPLES:
1.- %FixVarNames(thisisalongname v234567890test, max=10, space=2);
Returns the list 'thisisal v2345678'.

APPLICATIONS:
1.- Use this macro to shorten the variable names to make sure that when adding
a prefix or a suffix to them (with e.g. %MakeList) each generated variable name
is a valid SAS variable.
*/
&rsubmit;
%MACRO FixVarNames(var, max=32, space=0) / store des="Fixes variable names by shortening their names to an allowed maximum minus a space";
%local i;
%local maxchar;
%local lastchar;		%* Last character to keep in each variable name (this is used to avoid an out-of-range error in the %substr() macro when trimming variable names);
%local nro_vars;
%local vari;
%local varout;

%let nro_vars = %GetNroElements(&var);
%let maxchar = %eval(&max - &space);
%do i = 1 %to &nro_vars;
	%let vari = %scan(&var, &i, ' ');
	%let lastchar = %sysfunc(min(%length(&vari), &maxchar));
	%let varout = &varout %substr(&vari, 1, &lastchar);
%end;

&varout
%MEND FixVarNames;
